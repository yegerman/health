import Foundation

class InsightsEngine: ObservableObject {
    @Published var insights: [HealthInsight] = []
    @Published var dailyInsights: [HealthInsight] = []
    @Published var isGenerating = false

    func generateInsights(
        steps: [HealthDataPoint],
        heartRate: [HealthDataPoint],
        sleep: [HealthDataPoint],
        calories: [HealthDataPoint],
        workouts: [WorkoutData]
    ) {
        isGenerating = true
        insights = []

        analyzeSteps(steps)
        analyzeHeartRate(heartRate)
        analyzeSleep(sleep)
        analyzeActivity(calories, workouts: workouts)
        analyzeWeeklyTrends(steps: steps, sleep: sleep)
        analyzePatternsAndCorrelations(steps: steps, sleep: sleep)

        isGenerating = false
    }

    func generateDailyInsights(
        todaySteps: Int,
        yesterdaySteps: Int,
        lastNightSleep: Double
    ) {
        dailyInsights = []

        // Steps comparison
        if todaySteps > yesterdaySteps && yesterdaySteps > 0 {
            let percentIncrease = Double(todaySteps - yesterdaySteps) / Double(yesterdaySteps) * 100
            addDailyInsight(
                type: .positive,
                title: "📈 Progress",
                message: "You're \(Int(percentIncrease))% more active than yesterday!"
            )
        }

        // Sleep quality
        if lastNightSleep < 6 {
            addDailyInsight(
                type: .warning,
                title: "😴 Sleep Alert",
                message: "You only got \(String(format: "%.1f", lastNightSleep)) hours of sleep last night. Aim for 7-9 hours."
            )
        } else if lastNightSleep >= 7 && lastNightSleep <= 9 {
            addDailyInsight(
                type: .positive,
                title: "✨ Well Rested",
                message: "Great sleep! You got \(String(format: "%.1f", lastNightSleep)) hours last night."
            )
        }
    }

    // MARK: - Step Analysis

    private func analyzeSteps(_ data: [HealthDataPoint]) {
        guard !data.isEmpty else { return }

        let last7Days = getLastNDays(data, days: 7)
        let last30Days = getLastNDays(data, days: 30)

        let avg7Days = calculateDailyAverage(last7Days)
        let avg30Days = calculateDailyAverage(last30Days)
        let dailyGoal = 10000.0

        // Goal achievement
        if avg7Days >= dailyGoal {
            addInsight(
                type: .positive,
                title: "🎯 Step Goal Champion",
                message: "Amazing! You're averaging \(Int(avg7Days).formatted()) steps per day this week, exceeding the recommended 10,000 steps."
            )
        } else if avg7Days >= dailyGoal * 0.7 {
            addInsight(
                type: .info,
                title: "👟 Almost There",
                message: "You're averaging \(Int(avg7Days).formatted()) steps per day. Just \(Int(dailyGoal - avg7Days).formatted()) more steps to reach the daily goal!"
            )
        } else {
            addInsight(
                type: .warning,
                title: "🚶 Step It Up",
                message: "Your current average is \(Int(avg7Days).formatted()) steps per day. Try to increase your daily movement to reach 10,000 steps."
            )
        }

        // Trend analysis
        if avg7Days > avg30Days * 1.1 {
            let percentChange = Int((avg7Days - avg30Days) / avg30Days * 100)
            addInsight(
                type: .positive,
                title: "📈 Trending Up",
                message: "Great momentum! Your activity has increased by \(percentChange)% compared to your monthly average."
            )
        } else if avg7Days < avg30Days * 0.9 {
            let percentChange = Int((avg30Days - avg7Days) / avg30Days * 100)
            addInsight(
                type: .warning,
                title: "📉 Activity Dip",
                message: "Your step count is down \(percentChange)% this week. Let's get moving!"
            )
        }

        // Consistency
        let consistency = calculateConsistency(last7Days)
        if consistency > 0.8 {
            addInsight(
                type: .positive,
                title: "🎖️ Consistency Master",
                message: "You've been remarkably consistent with your daily activity. Keep up the great routine!"
            )
        }
    }

    // MARK: - Heart Rate Analysis

    private func analyzeHeartRate(_ data: [HealthDataPoint]) {
        guard data.count >= 50 else { return }

        let last7Days = getLastNDays(data, days: 7)
        let values = last7Days.map { $0.value }

        guard !values.isEmpty else { return }

        let minHR = Int(values.min() ?? 0)
        let maxHR = Int(values.max() ?? 0)
        let restingHR = minHR

        // Resting heart rate insights
        if restingHR < 60 {
            addInsight(
                type: .positive,
                title: "💪 Athletic Heart",
                message: "Your resting heart rate of \(restingHR) bpm indicates excellent cardiovascular fitness!"
            )
        } else if restingHR >= 60 && restingHR <= 100 {
            addInsight(
                type: .info,
                title: "💓 Healthy Heart",
                message: "Your resting heart rate of \(restingHR) bpm is within the normal range (60-100 bpm)."
            )
        } else {
            addInsight(
                type: .warning,
                title: "⚠️ Heart Rate Alert",
                message: "Your resting heart rate of \(restingHR) bpm is above normal. Consider consulting with a healthcare provider."
            )
        }

        // Heart rate variability
        let hrVariability = maxHR - minHR
        if hrVariability > 80 {
            addInsight(
                type: .info,
                title: "🏃 Active Lifestyle",
                message: "Your heart rate varies between \(minHR) and \(maxHR) bpm, showing you engage in various activity levels."
            )
        }
    }

    // MARK: - Sleep Analysis

    private func analyzeSleep(_ data: [HealthDataPoint]) {
        guard !data.isEmpty else { return }

        let last7Days = getLastNDays(data, days: 7)
        let avgSleep = calculateDailyAverage(last7Days)

        // Sleep recommendations: 7-9 hours
        if avgSleep >= 7 && avgSleep <= 9 {
            addInsight(
                type: .positive,
                title: "😴 Sleep Champion",
                message: "Perfect! You're averaging \(String(format: "%.1f", avgSleep)) hours of sleep per night, which is in the optimal range."
            )
        } else if avgSleep < 7 {
            let deficit = 7 - avgSleep
            addInsight(
                type: .warning,
                title: "⏰ Sleep Debt",
                message: "You're averaging \(String(format: "%.1f", avgSleep)) hours of sleep. Try to get \(String(format: "%.1f", deficit)) more hours per night for optimal health."
            )
        } else {
            addInsight(
                type: .info,
                title: "🛌 Long Sleeper",
                message: "You're averaging \(String(format: "%.1f", avgSleep)) hours of sleep. While this might work for you, most adults need 7-9 hours."
            )
        }

        // Sleep consistency
        let sleepValues = last7Days.map { $0.value }
        let stdDev = calculateStdDev(sleepValues)

        if stdDev < 0.5 {
            addInsight(
                type: .positive,
                title: "📅 Consistent Schedule",
                message: "Great job maintaining a consistent sleep schedule! This helps improve sleep quality."
            )
        } else if stdDev > 1.5 {
            addInsight(
                type: .warning,
                title: "⏱️ Irregular Sleep",
                message: "Your sleep duration varies significantly. Try to maintain a more consistent sleep schedule."
            )
        }
    }

    // MARK: - Activity Analysis

    private func analyzeActivity(_ calories: [HealthDataPoint], workouts: [WorkoutData]) {
        guard !calories.isEmpty else { return }

        let last7Days = getLastNDays(calories, days: 7)
        let avgCalories = calculateDailyAverage(last7Days)

        // Active energy recommendations
        if avgCalories >= 500 {
            addInsight(
                type: .positive,
                title: "🔥 Highly Active",
                message: "Excellent! You're burning an average of \(Int(avgCalories)) active calories per day."
            )
        } else if avgCalories >= 300 {
            addInsight(
                type: .info,
                title: "💪 Moderately Active",
                message: "You're burning \(Int(avgCalories)) active calories daily. Great work staying active!"
            )
        } else {
            addInsight(
                type: .warning,
                title: "🏃 Boost Your Activity",
                message: "Try to increase your activity level to burn more calories throughout the day."
            )
        }

        // Workout frequency
        if !workouts.isEmpty {
            let last7Workouts = workouts.filter { workout in
                Calendar.current.dateComponents([.day], from: workout.date, to: Date()).day ?? 100 <= 7
            }

            let uniqueDays = Set(last7Workouts.map { Calendar.current.startOfDay(for: $0.date) }).count

            if uniqueDays >= 5 {
                addInsight(
                    type: .positive,
                    title: "🏆 Fitness Enthusiast",
                    message: "Amazing dedication! You've worked out \(uniqueDays) times this week."
                )
            } else if uniqueDays >= 3 {
                addInsight(
                    type: .positive,
                    title: "💯 Active Week",
                    message: "Great job! \(uniqueDays) workouts this week keeps you on track for fitness goals."
                )
            } else if uniqueDays > 0 {
                addInsight(
                    type: .info,
                    title: "🎯 Room to Grow",
                    message: "You had \(uniqueDays) workout\(uniqueDays > 1 ? "s" : "") this week. Aim for at least 3-5 sessions per week."
                )
            }
        }
    }

    // MARK: - Weekly Trends

    private func analyzeWeeklyTrends(steps: [HealthDataPoint], sleep: [HealthDataPoint]) {
        let stepsLastWeek = getLastNDays(steps, days: 7)
        let stepsPreviousWeek = Array(getLastNDays(steps, days: 14).prefix(7))

        if !stepsLastWeek.isEmpty && !stepsPreviousWeek.isEmpty {
            let avgLast = calculateDailyAverage(stepsLastWeek)
            let avgPrevious = calculateDailyAverage(stepsPreviousWeek)
            let change = (avgLast - avgPrevious) / avgPrevious * 100

            if abs(change) > 10 {
                if change > 0 {
                    addInsight(
                        type: .positive,
                        title: "🚀 Weekly Progress",
                        message: "Your activity increased by \(Int(change))% compared to last week!"
                    )
                } else {
                    addInsight(
                        type: .warning,
                        title: "📊 Weekly Dip",
                        message: "Your activity decreased by \(Int(abs(change)))% this week. Let's bounce back!"
                    )
                }
            }
        }
    }

    // MARK: - Patterns and Correlations

    private func analyzePatternsAndCorrelations(steps: [HealthDataPoint], sleep: [HealthDataPoint]) {
        // Weekend vs Weekday patterns
        let weekdaySteps = steps.filter { !Calendar.current.isDateInWeekend($0.date) }
        let weekendSteps = steps.filter { Calendar.current.isDateInWeekend($0.date) }

        if !weekdaySteps.isEmpty && !weekendSteps.isEmpty {
            let avgWeekday = weekdaySteps.map { $0.value }.reduce(0, +) / Double(weekdaySteps.count)
            let avgWeekend = weekendSteps.map { $0.value }.reduce(0, +) / Double(weekendSteps.count)

            if avgWeekend < avgWeekday * 0.7 {
                addInsight(
                    type: .warning,
                    title: "📅 Weekend Slump",
                    message: "Your weekend activity is significantly lower. Try to stay active on weekends too!"
                )
            } else if avgWeekend > avgWeekday * 1.2 {
                addInsight(
                    type: .positive,
                    title: "🎉 Active Weekends",
                    message: "You're more active on weekends! Great way to balance a busy work week."
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func addInsight(type: InsightType, title: String, message: String) {
        let insight = HealthInsight(type: type, title: title, message: message)
        insights.append(insight)
    }

    private func addDailyInsight(type: InsightType, title: String, message: String) {
        let insight = HealthInsight(type: type, title: title, message: message)
        dailyInsights.append(insight)
    }

    private func getLastNDays(_ data: [HealthDataPoint], days: Int) -> [HealthDataPoint] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return data.filter { $0.date >= cutoffDate }
    }

    private func calculateDailyAverage(_ data: [HealthDataPoint]) -> Double {
        guard !data.isEmpty else { return 0 }

        var dateMap: [Date: Double] = [:]
        for point in data {
            let date = Calendar.current.startOfDay(for: point.date)
            dateMap[date, default: 0] += point.value
        }

        let dailyTotals = Array(dateMap.values)
        return dailyTotals.reduce(0, +) / Double(dailyTotals.count)
    }

    private func calculateStdDev(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }

        let avg = values.reduce(0, +) / Double(values.count)
        let squareDiffs = values.map { pow($0 - avg, 2) }
        let avgSquareDiff = squareDiffs.reduce(0, +) / Double(squareDiffs.count)

        return sqrt(avgSquareDiff)
    }

    private func calculateConsistency(_ data: [HealthDataPoint]) -> Double {
        guard !data.isEmpty else { return 0 }

        var dateMap: [Date: Double] = [:]
        for point in data {
            let date = Calendar.current.startOfDay(for: point.date)
            dateMap[date, default: 0] += point.value
        }

        let dailyTotals = Array(dateMap.values)
        let avg = dailyTotals.reduce(0, +) / Double(dailyTotals.count)
        let stdDev = calculateStdDev(dailyTotals)

        guard avg > 0 else { return 0 }

        let coefficientOfVariation = stdDev / avg
        return max(0, 1 - coefficientOfVariation)
    }
}

// MARK: - Models

struct HealthInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let timestamp = Date()

    var icon: String {
        switch type {
        case .positive: return "✅"
        case .warning: return "⚠️"
        case .info: return "ℹ️"
        }
    }
}

enum InsightType {
    case positive
    case warning
    case info

    var color: String {
        switch self {
        case .positive: return "green"
        case .warning: return "orange"
        case .info: return "blue"
        }
    }
}
