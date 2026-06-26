//
//  ContentView.swift
//  Workout_Tracking Watch App
//
//  Mode-aware watch UI: idle, data collection and live workout.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    var body: some View {
        VStack(spacing: 8) {
            connectionStatusView

            switch connectivityManager.currentMode {
            case .idle:
                idleView
            case .dataCollection:
                dataCollectionView
            case .workout:
                workoutView
            }
        }
        .padding()
        .onChange(of: connectivityManager.lastFeedback) { _, newFeedback in
            if let feedback = newFeedback {
                motionManager.updateFromFeedback(feedback)
            }
        }
    }

    // MARK: - Connection Status

    private var connectionStatusView: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(connectivityManager.isPhoneReachable ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(connectivityManager.isPhoneReachable ? "Connected" : "Waiting…")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 38))
                .foregroundStyle(.indigo)

            Text("Ready to train")
                .font(.headline)

            Text("Start a workout or data collection from your iPhone.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Data Collection View

    private var dataCollectionView: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(motionManager.isRecording ? Color.red : Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay {
                    VStack(spacing: 2) {
                        Image(systemName: motionManager.isRecording ? "waveform" : "pause.fill")
                            .font(.title2)
                        if motionManager.isRecording {
                            Text("\(motionManager.dataPointCount)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.white)
                }

            Text(motionManager.isRecording ? "Recording…" : "Waiting…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Workout View

    private var workoutView: some View {
        VStack(spacing: 6) {
            Text(connectivityManager.workoutExerciseName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("\(motionManager.workoutRepCount)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.indigo)
                .contentTransition(.numericText())

            Text("Reps")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if !motionManager.lastFeedback.isEmpty {
                feedbackBadge
            }

            if motionManager.isRecording {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 7, height: 7)
                    Text("Live")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Feedback Badge

    private var feedbackBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: motionManager.lastFeedbackIsCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.caption)

            Text(motionManager.lastFeedback)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            motionManager.lastFeedbackIsCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        )
        .foregroundStyle(
            motionManager.lastFeedbackIsCorrect ? .green : .red
        )
        .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
}
