import Foundation

class ClaudeAPIManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var apiKey: String = ""
    @Published var hasGreetedToday = false

    private let apiEndpoint = "https://openrouter.ai/api/v1/chat/completions"
    private let model = "google/gemini-flash-1.5"

    init() {
        loadAPIKey()
        loadMessages()
        checkDailyGreeting()
    }

    // MARK: - API Key Management

    func loadAPIKey() {
        if let key = UserDefaults.standard.string(forKey: "openrouter_api_key") {
            apiKey = key
        }
    }

    func saveAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "openrouter_api_key")
    }

    func hasAPIKey() -> Bool {
        return !apiKey.isEmpty
    }

    // MARK: - Proactive Greeting

    func checkDailyGreeting() {
        let lastGreetingDate = UserDefaults.standard.string(forKey: "last_greeting_date")
        let today = Date().formatted(date: .abbreviated, time: .omitted)

        if lastGreetingDate != today {
            hasGreetedToday = false
        } else {
            hasGreetedToday = true
        }
    }

    func generateProactiveGreeting(healthContext: String, userName: String = "there") async {
        guard !hasGreetedToday else { return }

        await MainActor.run {
            isLoading = true
        }

        // Build proactive greeting request
        let greetingPrompt = """
        Analyze the user's health data and greet them with a personalized, caring message.

        Be specific about what you notice in their data. If something looks concerning,
        mention it gently and ask how they're feeling. Be warm and supportive.

        Example: "Good morning! I noticed your sleep was only 5.2 hours last night and
        your resting heart rate is elevated at 72 bpm. How are you feeling today?"

        Keep it natural and conversational, not clinical.
        """

        await sendMessage(greetingPrompt, healthContext: healthContext, isProactive: true)

        // Mark as greeted
        let today = Date().formatted(date: .abbreviated, time: .omitted)
        UserDefaults.standard.set(today, forKey: "last_greeting_date")
        await MainActor.run {
            hasGreetedToday = true
        }
    }

    // MARK: - Chat

    func sendMessage(_ userMessage: String, healthContext: String, isProactive: Bool = false) async {
        // Add user message (unless it's proactive greeting)
        if !isProactive {
            let userMsg = ChatMessage(role: .user, content: userMessage)
            await MainActor.run {
                messages.append(userMsg)
                isLoading = true
            }
        } else {
            await MainActor.run {
                isLoading = true
            }
        }

        // Build conversation with FULL history (no limit)
        var conversationMessages: [[String: Any]] = []

        // Add ALL conversation history
        for msg in messages {
            conversationMessages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }

        // Add current message if not proactive
        if !isProactive {
            conversationMessages.append([
                "role": "user",
                "content": userMessage
            ])
        }

        // Prepare system prompt
        let systemPrompt = """
        You are Mor's personal AI health coach and diagnostic assistant. You have access to
        their complete Apple Health data and conversation history.

        Your Personality:
        - Caring, warm, and supportive
        - Proactive - you initiate check-ins
        - Observant - you notice patterns
        - Diagnostic - you ask questions to understand symptoms
        - Evidence-based - you reference actual data

        Your Capabilities:
        1. **Proactive Check-ins**: Greet Mor each morning with observations about their health
        2. **Pattern Recognition**: Notice changes in sleep, heart rate, activity, etc.
        3. **Diagnostic Conversations**: Ask questions to understand how they feel
        4. **Personalized Advice**: Give specific, actionable recommendations
        5. **Long-term Memory**: Remember all previous conversations and feedback

        Guidelines:
        - Always address Mor by name when greeting
        - Be specific with data (e.g., "I see your sleep was 6.2 hours" not "low sleep")
        - Ask follow-up questions based on health signals
        - If something seems off, ask "How are you feeling?" or "How's your energy?"
        - Track symptoms over time using conversation history
        - Suggest when to see a doctor if patterns are concerning
        - Use emojis naturally but not excessively
        - Be conversational, not clinical

        Current Health Data:
        \(healthContext)

        Remember: You're having a continuous conversation. Reference past discussions and
        track how Mor is doing over time.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ]
            ] + conversationMessages
        ]

        // Make API call
        do {
            guard let url = URL(string: apiEndpoint) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("HealthInsights/1.0", forHTTPHeaderField: "HTTP-Referer")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API Error: \(errorText)")
                throw APIError.apiError(statusCode: httpResponse.statusCode, message: errorText)
            }

            // Parse OpenRouter response format
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let text = message["content"] as? String {

                let assistantMsg = ChatMessage(role: .assistant, content: text)

                await MainActor.run {
                    messages.append(assistantMsg)
                    isLoading = false
                    saveMessages()
                }
            } else {
                throw APIError.invalidResponse
            }

        } catch {
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "Sorry, I encountered an error: \(error.localizedDescription). Please check your API key and internet connection."
            )

            await MainActor.run {
                messages.append(errorMsg)
                isLoading = false
            }
        }
    }

    // MARK: - Message Persistence (Full History)

    func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: "chat_messages")
        }
    }

    func loadMessages() {
        if let data = UserDefaults.standard.data(forKey: "chat_messages"),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = decoded
        }
    }

    func clearMessages() {
        messages = []
        UserDefaults.standard.removeObject(forKey: "chat_messages")
        UserDefaults.standard.removeObject(forKey: "last_greeting_date")
        hasGreetedToday = false
    }
}

// MARK: - Models

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        }
    }
}
