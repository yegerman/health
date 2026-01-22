import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var insightsEngine: InsightsEngine
    @State private var showingDailyInsights = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Insights")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Personalized analysis of your health data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    // Toggle between Daily and All Insights
                    Picker("Insight Type", selection: $showingDailyInsights) {
                        Text("Daily").tag(true)
                        Text("All Insights").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Generate Insights Button
                    if !showingDailyInsights {
                        Button(action: generateInsights) {
                            HStack {
                                if insightsEngine.isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate Insights")
                                }
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(insightsEngine.isGenerating)
                        .padding(.horizontal)
                    }

                    // Insights Display
                    if showingDailyInsights {
                        if insightsEngine.dailyInsights.isEmpty {
                            EmptyInsightsView(type: "daily")
                        } else {
                            ForEach(insightsEngine.dailyInsights) { insight in
                                InsightCard(insight: insight)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        if insightsEngine.insights.isEmpty {
                            EmptyInsightsView(type: "general")
                        } else {
                            ForEach(insightsEngine.insights) { insight in
                                InsightCard(insight: insight)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                generateDailyInsights()
            }
        }
    }

    private func generateInsights() {
        insightsEngine.generateInsights(
            steps: healthManager.stepsHistory,
            heartRate: healthManager.heartRateHistory,
            sleep: healthManager.sleepHistory,
            calories: healthManager.caloriesHistory,
            workouts: healthManager.workoutHistory
        )
    }

    private func generateDailyInsights() {
        // Calculate yesterday's steps
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdaySteps = healthManager.stepsHistory
            .filter { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }
            .reduce(0) { $0 + Int($1.value) }

        insightsEngine.generateDailyInsights(
            todaySteps: healthManager.todaySteps,
            yesterdaySteps: yesterdaySteps,
            lastNightSleep: healthManager.todaySleep
        )
    }
}

struct InsightCard: View {
    let insight: HealthInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Text(insight.icon)
                .font(.title2)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(insight.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insightColor(insight.type), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func insightColor(_ type: InsightType) -> Color {
        switch type {
        case .positive: return .green
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct EmptyInsightsView: View {
    let type: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            if type == "daily" {
                Text("No daily insights yet")
                    .font(.headline)

                Text("Daily insights will appear based on your activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No insights generated")
                    .font(.headline)

                Text("Tap 'Generate Insights' to analyze your health data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    InsightsView()
        .environmentObject(HealthKitManager())
        .environmentObject(InsightsEngine())
}
