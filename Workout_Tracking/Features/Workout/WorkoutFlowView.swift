//
//  WorkoutFlowView.swift
//  Workout_Tracking
//
//  Orchestrates the full workout experience presented as a cover:
//  pick exercise → countdown → live session → summary (saved).
//

import SwiftUI

struct WorkoutFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var connectivity: PhoneConnectivityManager
    @StateObject private var workoutManager = WorkoutManager.shared

    private enum Phase { case picker, countdown, active, summary }
    @State private var phase: Phase = .picker
    @State private var selectedExercise: Exercise = .bicepCurl
    @State private var countdown = 5
    @State private var countdownTimer: Timer?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if phase == .picker || phase == .summary {
                Button { close() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            } else {
                Color.clear.frame(width: 36, height: 36)
            }

            Spacer()

            Text(phase == .picker ? "New Workout" : selectedExercise.displayName)
                .font(.headline)

            Spacer()

            ConnectionChipCompact(isConnected: connectivity.isWatchReachable)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Phases

    @ViewBuilder private var content: some View {
        switch phase {
        case .picker:
            ExercisePickerView { exercise in
                selectedExercise = exercise
                startCountdown()
            }
        case .countdown:
            countdownView
        case .active:
            ActiveWorkoutView(onStop: stopWorkout)
        case .summary:
            WorkoutSummaryView(onClose: close)
        }
    }

    private var countdownView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Get ready!")
                .font(.title2.weight(.semibold))

            ProgressRing(
                progress: Double(countdown) / 5.0,
                lineWidth: 12,
                color: selectedExercise.tint
            ) {
                Text("\(countdown)")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(selectedExercise.tint)
                    .contentTransition(.numericText())
            }
            .frame(width: 200, height: 200)

            Text("Get your watch arm in position")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Transitions

    private func startCountdown() {
        countdown = 5
        phase = .countdown
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation {
                if countdown > 1 {
                    countdown -= 1
                } else {
                    countdownTimer?.invalidate()
                    countdownTimer = nil
                    beginWorkout()
                }
            }
        }
    }

    private func beginWorkout() {
        workoutManager.startWorkout(exercise: selectedExercise)
        connectivity.sendWorkoutStartCommand(exerciseName: selectedExercise.displayName)
        phase = .active
    }

    private func stopWorkout() {
        workoutManager.stopWorkout()
        connectivity.sendWorkoutStopCommand()
        withAnimation { phase = .summary }
    }

    private func close() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        if workoutManager.isWorkoutActive {
            workoutManager.stopWorkout()
            connectivity.sendWorkoutStopCommand()
        }
        dismiss()
    }
}

/// Slimmer connection chip for the flow header.
struct ConnectionChipCompact: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isConnected ? "applewatch" : "applewatch.slash")
            Circle()
                .fill(isConnected ? Theme.correct : Theme.tooFast)
                .frame(width: 7, height: 7)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
