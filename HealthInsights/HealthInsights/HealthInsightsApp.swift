import SwiftUI

@main
struct HealthInsightsApp: App {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var insightsEngine = InsightsEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
                .environmentObject(insightsEngine)
                .onAppear {
                    healthManager.requestAuthorization()
                }
        }
    }
}
