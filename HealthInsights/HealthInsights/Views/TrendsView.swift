import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var selectedMetric: HealthMetric = .steps
    @State private var selectedPeriod: TimePeriod = .week

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Trends")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Visualize your health data over time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    // Metric Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metric")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(HealthMetric.allCases, id: \.self) { metric in
                                Text(metric.rawValue).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    // Period Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Period")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    // Chart
                    VStack(alignment: .leading, spacing: 12) {
                        // Stats Summary
                        HStack(spacing: 20) {
                            StatSummary(
                                title: "Average",
                                value: averageValue,
                                unit: selectedMetric.unit
                            )

                            StatSummary(
                                title: "Highest",
                                value: maxValue,
                                unit: selectedMetric.unit
                            )

                            StatSummary(
                                title: "Lowest",
                                value: minValue,
                                unit: selectedMetric.unit
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Chart
                        if !chartData.isEmpty {
                            Chart {
                                ForEach(chartData) { dataPoint in
                                    LineMark(
                                        x: .value("Date", dataPoint.date),
                                        y: .value("Value", dataPoint.value)
                                    )
                                    .foregroundStyle(selectedMetric.color)
                                    .interpolationMethod(.catmullRom)

                                    AreaMark(
                                        x: .value("Date", dataPoint.date),
                                        y: .value("Value", dataPoint.value)
                                    )
                                    .foregroundStyle(
                                        selectedMetric.color.opacity(0.1)
                                    )
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                            .frame(height: 300)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5))
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        } else {
                            EmptyChartView()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var chartData: [HealthDataPoint] {
        let data: [HealthDataPoint]
        switch selectedMetric {
        case .steps:
            data = healthManager.stepsHistory
        case .heartRate:
            data = healthManager.heartRateHistory
        case .sleep:
            data = healthManager.sleepHistory
        case .calories:
            data = healthManager.caloriesHistory
        }

        let days = selectedPeriod.days
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Group by day and average
        var dailyData: [Date: [Double]] = [:]
        for point in data where point.date >= cutoffDate {
            let day = Calendar.current.startOfDay(for: point.date)
            dailyData[day, default: []].append(point.value)
        }

        let aggregated = dailyData.map { date, values in
            HealthDataPoint(date: date, value: values.reduce(0, +) / Double(values.count))
        }.sorted { $0.date < $1.date }

        return aggregated
    }

    var averageValue: String {
        guard !chartData.isEmpty else { return "--" }
        let avg = chartData.map { $0.value }.reduce(0, +) / Double(chartData.count)
        return formatValue(avg)
    }

    var maxValue: String {
        guard !chartData.isEmpty else { return "--" }
        let max = chartData.map { $0.value }.max() ?? 0
        return formatValue(max)
    }

    var minValue: String {
        guard !chartData.isEmpty else { return "--" }
        let min = chartData.map { $0.value }.min() ?? 0
        return formatValue(min)
    }

    func formatValue(_ value: Double) -> String {
        if selectedMetric == .sleep {
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        } else {
            return "\(Int(value))"
        }
    }
}

struct StatSummary: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)

                if !unit.isEmpty && value != "--" {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No data available")
                .font(.headline)

            Text("Health data will appear here once synced")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
}

enum HealthMetric: String, CaseIterable {
    case steps = "Steps"
    case heartRate = "Heart Rate"
    case sleep = "Sleep"
    case calories = "Calories"

    var unit: String {
        switch self {
        case .steps: return "steps"
        case .heartRate: return "bpm"
        case .sleep: return ""
        case .calories: return "kcal"
        }
    }

    var color: Color {
        switch self {
        case .steps: return .green
        case .heartRate: return .red
        case .sleep: return .blue
        case .calories: return .orange
        }
    }
}

enum TimePeriod: String, CaseIterable {
    case week = "7 Days"
    case twoWeeks = "14 Days"
    case month = "30 Days"

    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }
}

#Preview {
    TrendsView()
        .environmentObject(HealthKitManager())
}
