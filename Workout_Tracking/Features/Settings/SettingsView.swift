//
//  SettingsView.swift
//  Workout_Tracking
//
//  Preferences, Apple Watch status, the relocated data-collection
//  tool (Developer) and app info.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var connectivity: PhoneConnectivityManager
    @Environment(\.modelContext) private var modelContext
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 4
    @Query private var sessions: [WorkoutSession]

    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly goal") {
                    Stepper(value: $weeklyGoal, in: 1...14) {
                        HStack {
                            Label("Workouts per week", systemImage: "target")
                            Spacer()
                            Text("\(weeklyGoal)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Apple Watch") {
                    LabeledContent {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(connectivity.isWatchReachable ? Theme.correct : Theme.tooFast)
                                .frame(width: 8, height: 8)
                            Text(connectivity.isWatchReachable ? "Connected" : "Not reachable")
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        Label("Status", systemImage: "applewatch")
                    }
                    LabeledContent {
                        Text(connectivity.isWatchAppInstalled ? "Installed" : "Not installed")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Watch app", systemImage: "app.badge")
                    }
                }

                Section {
                    NavigationLink {
                        GetDataView()
                    } label: {
                        Label("Collect Training Data", systemImage: "waveform.badge.plus")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Record labelled motion samples to train and improve the on-device model.")
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Delete all history", systemImage: "trash")
                    }
                    .disabled(sessions.isEmpty)
                }

                Section {
                    LabeledContent("Form model", value: "On-device · Random Forest")
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("Forma — your AI form coach.\nML project · FH Hagenberg")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all workout history?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete \(sessions.count) workouts", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every saved session and can't be undone.")
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func deleteAll() {
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .environmentObject(PhoneConnectivityManager.shared)
        .modelContainer(for: [WorkoutSession.self, RepRecord.self], inMemory: true)
}
