import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()

    @Published var todaySteps: Int = 0
    @Published var todayHeartRate: Double = 0
    @Published var todaySleep: Double = 0
    @Published var todayCalories: Double = 0
    @Published var todayWeight: Double = 0

    @Published var stepsHistory: [HealthDataPoint] = []
    @Published var heartRateHistory: [HealthDataPoint] = []
    @Published var sleepHistory: [HealthDataPoint] = []
    @Published var caloriesHistory: [HealthDataPoint] = []
    @Published var workoutHistory: [WorkoutData] = []

    @Published var isAuthorized = false
    @Published var lastSyncDate: Date?

    // Data types we want to read
    private let typesToRead: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available")
            return
        }

        // Check if we have authorization for all types
        let allTypesAuthorized = typesToRead.allSatisfy { type in
            healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }

        DispatchQueue.main.async {
            self.isAuthorized = allTypesAuthorized
        }

        if allTypesAuthorized {
            fetchAllData()
        }
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available")
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchAllData()
                }
            }

            if let error = error {
                print("Authorization error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch All Data

    func fetchAllData() {
        fetchSteps()
        fetchHeartRate()
        fetchSleep()
        fetchActiveCalories()
        fetchWorkouts()

        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }

    // MARK: - Steps

    func fetchSteps(days: Int = 30) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: Calendar.current.startOfDay(for: Date()),
            intervalComponents: DateComponents(day: 1)
        )

        query.initialResultsHandler = { _, results, error in
            guard let results = results else { return }

            var dataPoints: [HealthDataPoint] = []
            var todayTotal = 0.0

            results.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let value = sum.doubleValue(for: .count())
                    let dataPoint = HealthDataPoint(
                        date: statistics.startDate,
                        value: value
                    )
                    dataPoints.append(dataPoint)

                    // Check if this is today
                    if Calendar.current.isDateInToday(statistics.startDate) {
                        todayTotal = value
                    }
                }
            }

            DispatchQueue.main.async {
                self.stepsHistory = dataPoints
                self.todaySteps = Int(todayTotal)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Heart Rate

    func fetchHeartRate(days: Int = 30) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample] else { return }

            var dataPoints: [HealthDataPoint] = []
            var todayValues: [Double] = []

            for sample in samples {
                let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                let dataPoint = HealthDataPoint(
                    date: sample.startDate,
                    value: value
                )
                dataPoints.append(dataPoint)

                if Calendar.current.isDateInToday(sample.startDate) {
                    todayValues.append(value)
                }
            }

            let todayAverage = todayValues.isEmpty ? 0 : todayValues.reduce(0, +) / Double(todayValues.count)

            DispatchQueue.main.async {
                self.heartRateHistory = dataPoints
                self.todayHeartRate = todayAverage
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Sleep

    func fetchSleep(days: Int = 30) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else { return }

            var dailySleep: [Date: TimeInterval] = [:]

            for sample in samples {
                // Only count asleep time (not in bed)
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    let date = Calendar.current.startOfDay(for: sample.startDate)
                    dailySleep[date, default: 0] += duration
                }
            }

            let dataPoints = dailySleep.map { date, duration in
                HealthDataPoint(date: date, value: duration / 3600.0) // Convert to hours
            }.sorted { $0.date < $1.date }

            // Last night's sleep
            let yesterday = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
            let lastNightSleep = dailySleep[yesterday] ?? 0

            DispatchQueue.main.async {
                self.sleepHistory = dataPoints
                self.todaySleep = lastNightSleep / 3600.0
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Active Calories

    func fetchActiveCalories(days: Int = 30) {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: calorieType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: Calendar.current.startOfDay(for: Date()),
            intervalComponents: DateComponents(day: 1)
        )

        query.initialResultsHandler = { _, results, error in
            guard let results = results else { return }

            var dataPoints: [HealthDataPoint] = []
            var todayTotal = 0.0

            results.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let value = sum.doubleValue(for: .kilocalorie())
                    let dataPoint = HealthDataPoint(
                        date: statistics.startDate,
                        value: value
                    )
                    dataPoints.append(dataPoint)

                    if Calendar.current.isDateInToday(statistics.startDate) {
                        todayTotal = value
                    }
                }
            }

            DispatchQueue.main.async {
                self.caloriesHistory = dataPoints
                self.todayCalories = todayTotal
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Workouts

    func fetchWorkouts(days: Int = 30) {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let workouts = samples as? [HKWorkout] else { return }

            let workoutData = workouts.map { workout in
                WorkoutData(
                    date: workout.startDate,
                    type: workout.workoutActivityType.name,
                    duration: workout.duration / 60.0, // Convert to minutes
                    calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                )
            }

            DispatchQueue.main.async {
                self.workoutHistory = workoutData
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Background Refresh

    func setupBackgroundDelivery() {
        guard isAuthorized else { return }

        for type in typesToRead {
            healthStore.enableBackgroundDelivery(for: type, frequency: .daily) { success, error in
                if let error = error {
                    print("Background delivery error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Data Models

struct HealthDataPoint: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let value: Double

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct WorkoutData: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let type: String
    let duration: Double // minutes
    let calories: Double
}

// MARK: - Extensions

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .coreTraining: return "Core Training"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stairs"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .tennis: return "Tennis"
        default: return "Workout"
        }
    }
}
