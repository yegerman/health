import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var healthManager: HealthKitManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Good \(timeOfDay)")
                            .font(.title)
                            .fontWeight(.bold)

                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let lastSync = healthManager.lastSyncDate {
                            Text("Last synced: \(lastSync.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            icon: "figure.walk",
                            title: "Steps",
                            value: "\(healthManager.todaySteps.formatted())",
                            color: .green
                        )

                        StatCard(
                            icon: "heart.fill",
                            title: "Heart Rate",
                            value: healthManager.todayHeartRate > 0 ? "\(Int(healthManager.todayHeartRate)) bpm" : "--",
                            color: .red
                        )

                        StatCard(
                            icon: "bed.double.fill",
                            title: "Sleep",
                            value: healthManager.todaySleep > 0 ? formatSleep(healthManager.todaySleep) : "--",
                            color: .blue
                        )

                        StatCard(
                            icon: "flame.fill",
                            title: "Active Calories",
                            value: healthManager.todayCalories > 0 ? "\(Int(healthManager.todayCalories))" : "--",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Daily Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Summary")
                            .font(.headline)

                        if healthManager.todaySteps == 0 && !healthManager.isAuthorized {
                            Text("Grant Health access to see your daily summary.")
                                .font(.body)
                                .foregroundColor(.secondary)

                            Button(action: {
                                healthManager.requestAuthorization()
                            }) {
                                Text("Grant Access")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.pink)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        } else if healthManager.todaySteps > 0 {
                            SummaryText(steps: healthManager.todaySteps, calories: healthManager.todayCalories)
                        } else {
                            Text("Start your day with some activity!")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Refresh Button
                    Button(action: {
                        healthManager.fetchAllData()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Data")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Health Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }

    func formatSleep(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct SummaryText: View {
    let steps: Int
    let calories: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if steps >= 10000 {
                Text("🎉 Great job! You've hit your 10,000 step goal today.")
            } else if steps > 5000 {
                Text("💪 You're making progress with \(steps.formatted()) steps so far.")
            } else if steps > 0 {
                Text("🚶 You've taken \(steps.formatted()) steps today. Keep moving!")
            }

            if calories > 500 {
                Text("🔥 You've burned \(Int(calories)) active calories.")
            }
        }
        .font(.body)
    }
}

#Preview {
    DashboardView()
        .environmentObject(HealthKitManager())
}
