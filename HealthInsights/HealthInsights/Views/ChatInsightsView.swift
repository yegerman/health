import SwiftUI

struct ChatInsightsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var claudeAPI = ClaudeAPIManager()
    @State private var messageText = ""
    @State private var showingAPIKeySheet = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Check for API key
                if !claudeAPI.hasAPIKey() {
                    apiKeySetupView
                } else {
                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                // Welcome message
                                if claudeAPI.messages.isEmpty {
                                    welcomeView
                                }

                                // Chat messages
                                ForEach(claudeAPI.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                // Loading indicator
                                if claudeAPI.isLoading {
                                    HStack {
                                        ProgressView()
                                        Text("Analyzing your health data...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: claudeAPI.messages.count) { _ in
                            if let lastMessage = claudeAPI.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    Divider()

                    // Input area
                    inputView
                }
            }
            .navigationTitle("AI Health Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingAPIKeySheet = true
                        }) {
                            Label("API Settings", systemImage: "key")
                        }

                        Button(action: {
                            claudeAPI.clearMessages()
                        }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAPIKeySheet) {
                APIKeySetupSheet(claudeAPI: claudeAPI)
            }
        }
        .onAppear {
            claudeAPI.loadMessages()
        }
    }

    // MARK: - Welcome View

    var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)

            Text("Your AI Health Coach")
                .font(.title2)
                .fontWeight(.bold)

            Text("I'm here to check in on your health, answer questions, and provide personalized insights based on your Apple Health data.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("I'll greet you each morning with observations about your health! 👋")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .onAppear {
            // Generate proactive greeting when user opens the app
            Task {
                let healthContext = buildHealthContext()
                await claudeAPI.generateProactiveGreeting(healthContext: healthContext, userName: "Mor")
            }
        }
    }

    // MARK: - Preset Questions

    var presetQuestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PresetButton(
                        icon: "figure.walk",
                        text: "How's my activity level?",
                        color: .green
                    ) {
                        sendPresetQuestion("How's my activity level? Am I hitting my daily step goals?")
                    }

                    PresetButton(
                        icon: "bed.double.fill",
                        text: "Sleep quality",
                        color: .blue
                    ) {
                        sendPresetQuestion("How is my sleep quality? Am I getting enough rest?")
                    }

                    PresetButton(
                        icon: "heart.fill",
                        text: "Heart health",
                        color: .red
                    ) {
                        sendPresetQuestion("What does my heart rate data tell you about my cardiovascular health?")
                    }

                    PresetButton(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Weekly trends",
                        color: .orange
                    ) {
                        sendPresetQuestion("What are the key trends in my health data this week?")
                    }

                    PresetButton(
                        icon: "lightbulb.fill",
                        text: "Recommendations",
                        color: .purple
                    ) {
                        sendPresetQuestion("Based on my data, what are your top 3 health recommendations for me?")
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Input View

    var inputView: some View {
        HStack(spacing: 12) {
            TextField("Ask about your health...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .focused($isInputFocused)
                .lineLimit(1...5)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .gray : .pink)
            }
            .disabled(messageText.isEmpty || claudeAPI.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - API Key Setup

    var apiKeySetupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)

            Text("OpenRouter API Key Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("To use AI-powered health insights with Gemini Flash 1.5, you need an OpenRouter API key.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                showingAPIKeySheet = true
            }) {
                Text("Set Up API Key")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Link("Get API Key from OpenRouter", destination: URL(string: "https://openrouter.ai/keys")!)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
    }

    // MARK: - Actions

    func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""
        isInputFocused = false

        Task {
            let healthContext = buildHealthContext()
            await claudeAPI.sendMessage(text, healthContext: healthContext)
        }
    }

    func sendPresetQuestion(_ question: String) {
        messageText = question
        sendMessage()
    }

    func buildHealthContext() -> String {
        var context = "# Current Health Data\n\n"

        // Today's stats
        context += "## Today's Summary\n"
        context += "- Steps: \(healthManager.todaySteps.formatted())\n"
        context += "- Heart Rate: \(healthManager.todayHeartRate > 0 ? "\(Int(healthManager.todayHeartRate)) bpm" : "No data")\n"
        context += "- Sleep (last night): \(healthManager.todaySleep > 0 ? String(format: "%.1f hours", healthManager.todaySleep) : "No data")\n"
        context += "- Active Calories: \(healthManager.todayCalories > 0 ? "\(Int(healthManager.todayCalories)) kcal" : "No data")\n\n"

        // 7-day averages
        context += "## 7-Day Averages\n"
        let last7Steps = healthManager.stepsHistory.suffix(7)
        if !last7Steps.isEmpty {
            let avgSteps = last7Steps.reduce(0) { $0 + $1.value } / Double(last7Steps.count)
            context += "- Average Steps: \(Int(avgSteps).formatted()) steps/day\n"
        }

        let last7HR = healthManager.heartRateHistory.suffix(7)
        if !last7HR.isEmpty {
            let avgHR = last7HR.reduce(0) { $0 + $1.value } / Double(last7HR.count)
            context += "- Average Heart Rate: \(Int(avgHR)) bpm\n"
        }

        let last7Sleep = healthManager.sleepHistory.suffix(7)
        if !last7Sleep.isEmpty {
            let avgSleep = last7Sleep.reduce(0) { $0 + $1.value } / Double(last7Sleep.count)
            context += "- Average Sleep: \(String(format: "%.1f", avgSleep)) hours/night\n"
        }

        let last7Cal = healthManager.caloriesHistory.suffix(7)
        if !last7Cal.isEmpty {
            let avgCal = last7Cal.reduce(0) { $0 + $1.value } / Double(last7Cal.count)
            context += "- Average Active Calories: \(Int(avgCal)) kcal/day\n"
        }

        // Recent workouts
        if !healthManager.workoutHistory.isEmpty {
            context += "\n## Recent Workouts (Last 7 Days)\n"
            let recentWorkouts = healthManager.workoutHistory.prefix(7)
            for workout in recentWorkouts {
                context += "- \(workout.type): \(String(format: "%.0f", workout.duration)) minutes (\(Int(workout.calories)) kcal)\n"
            }
        }

        return context
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.pink : Color(.systemGray6))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)
                    .textSelection(.enabled)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(text)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 120, height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - API Key Setup Sheet

struct APIKeySetupSheet: View {
    @ObservedObject var claudeAPI: ClaudeAPIManager
    @Environment(\.dismiss) var dismiss
    @State private var apiKeyInput = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Enter your OpenRouter API key to enable AI-powered health insights with Gemini Flash 1.5.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section("API Key") {
                    SecureField("sk-or-v1-...", text: $apiKeyInput)
                        .textContentType(.password)
                        .autocorrectionDisabled()

                    Link("Get API Key from OpenRouter →", destination: URL(string: "https://openrouter.ai/keys")!)
                        .font(.caption)
                }

                Section("Model Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Model:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("Gemini Flash 1.5")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Cost:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("~$0.0001 per message")
                                .foregroundColor(.secondary)
                        }

                        Text("Very affordable for daily use!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Save API Key") {
                        claudeAPI.saveAPIKey(apiKeyInput)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(apiKeyInput.isEmpty)
                }

                Section {
                    Text("Privacy Note")
                        .font(.headline)

                    Text("Your health data will be sent to OpenRouter (using Google's Gemini) for analysis. OpenRouter does not train on user data. For maximum privacy, consider using a self-hosted LLM solution.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("API Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                apiKeyInput = claudeAPI.apiKey
            }
        }
    }
}

#Preview {
    ChatInsightsView()
        .environmentObject(HealthKitManager())
}
