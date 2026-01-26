import Foundation

class ClaudeAPIManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var apiKey: String = ""

    private let apiEndpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-5-sonnet-20241022"

    init() {
        loadAPIKey()
    }

    // MARK: - API Key Management

    func loadAPIKey() {
        if let key = UserDefaults.standard.string(forKey: "claude_api_key") {
            apiKey = key
        }
    }

    func saveAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "claude_api_key")
    }

    func hasAPIKey() -> Bool {
        return !apiKey.isEmpty
    }

    // MARK: - Chat

    func sendMessage(_ userMessage: String, healthContext: String) async {
        // Add user message
        let userMsg = ChatMessage(role: .user, content: userMessage)
        await MainActor.run {
            messages.append(userMsg)
            isLoading = true
        }

        // Build conversation history
        var conversationMessages: [[String: Any]] = []

        // Add conversation history (last 10 messages)
        let recentMessages = messages.suffix(10)
        for msg in recentMessages {
            conversationMessages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }

        // Prepare request
        let systemPrompt = """
        You are a health insights assistant analyzing Apple Health data. You provide personalized,
        evidence-based health insights and answer questions about the user's health metrics.

        Guidelines:
        - Be encouraging and supportive
        - Reference specific data points when making observations
        - Provide actionable recommendations
        - Mention when medical consultation may be needed
        - Focus on trends and patterns
        - Use emojis appropriately for engagement

        Here is the user's current health data:

        \(healthContext)

        Analyze this data and provide insights based on the user's questions.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": conversationMessages
        ]

        // Make API call
        do {
            guard let url = URL(string: apiEndpoint) else {
                throw APIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
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

            // Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let firstContent = content.first,
               let text = firstContent["text"] as? String {

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

    // MARK: - Message Persistence

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
