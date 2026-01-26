import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var dailyInsightTime = Date()
    @State private var showingExportSheet = false
    @State private var showingClearAlert = false

    var body: some View {
        NavigationView {
            List {
                // Health Data Section
                Section {
                    HStack {
                        Label("Health Access", systemImage: "heart.text.square")
                        Spacer()
                        if healthManager.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("Grant Access") {
                                healthManager.requestAuthorization()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let lastSync = healthManager.lastSyncDate {
                        HStack {
                            Label("Last Sync", systemImage: "arrow.clockwise")
                            Spacer()
                            Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }

                    Button(action: {
                        healthManager.fetchAllData()
                    }) {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("Health Data")
                }

                // Notifications Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Daily Insights", systemImage: "bell.fill")
                    }

                    if notificationsEnabled {
                        DatePicker(
                            "Notification Time",
                            selection: $dailyInsightTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Receive daily health insights at your preferred time")
                }

                // Data Management Section
                Section {
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive, action: {
                        showingClearAlert = true
                    }) {
                        Label("Clear All Data", systemImage: "trash")
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Export or clear your locally cached health data")
                }

                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }

                    Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All your health data is processed locally on your device. Nothing is sent to external servers.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Made with 💚 for better health insights")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Data", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearData()
                }
            } message: {
                Text("This will clear all locally cached health data. Your Apple Health data will not be affected. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView()
            }
        }
    }

    private func clearData() {
        // Reset all published properties
        healthManager.todaySteps = 0
        healthManager.todayHeartRate = 0
        healthManager.todaySleep = 0
        healthManager.todayCalories = 0
        healthManager.stepsHistory = []
        healthManager.heartRateHistory = []
        healthManager.sleepHistory = []
        healthManager.caloriesHistory = []
        healthManager.workoutHistory = []
        healthManager.lastSyncDate = nil
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isExporting = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("Export Health Data")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Export your processed health insights as JSON")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    exportData()
                }) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Export")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isExporting)

                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportData() {
        isExporting = true

        // Simulate export (in real app, this would create and share a file)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isExporting = false
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(HealthKitManager())
}
