//
//  WorkoutView.swift
//  Workout_Tracking
//
//  The live, in-progress workout screen (used inside WorkoutFlowView).
//  Form-graded exercises show a live accuracy ring; count-only
//  exercises show a big rep counter.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    let onStop: () -> Void

    private var grades: Bool { workoutManager.currentExercise.supportsFormGrading }
    private var stats: WorkoutStats { workoutManager.stats }
    private var formPct: Double { stats.correctPercentage }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                hero
                    .padding(.top, 8)

                if grades {
                    statsRow
                }

                feedbackBanner

                if grades && !workoutManager.repResults.isEmpty {
                    recentReps
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            GradientButton(
                title: "End Workout",
                systemImage: "stop.fill",
                gradient: Theme.gradient(for: Theme.tooFast),
                shadowColor: Theme.tooFast,
                action: onStop
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Hero

    @ViewBuilder private var hero: some View {
        if grades {
            ProgressRing(
                progress: formPct / 100,
                lineWidth: 18,
                color: Theme.color(forFormScore: formPct)
            ) {
                VStack(spacing: 2) {
                    Text("\(Int(formPct))%")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("Form")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 210, height: 210)
        } else {
            ZStack {
                Circle()
                    .fill(Theme.gradient(for: workoutManager.currentExercise.tint))
                VStack(spacing: 0) {
                    Text("\(stats.totalReps)")
                        .font(.system(size: 70, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("REPS")
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(width: 210, height: 210)
            .shadow(color: workoutManager.currentExercise.tint.opacity(0.35), radius: 16, y: 8)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBox(title: "Reps", value: "\(stats.totalReps)", color: Theme.brand)
            StatBox(title: "Correct", value: "\(stats.correctReps)", color: Theme.correct)
            StatBox(title: "To fix", value: "\(stats.halfRomReps + stats.tooFastReps)", color: Theme.tooFast)
        }
        .cardStyle()
    }

    // MARK: - Feedback banner

    private var feedbackBanner: some View {
        HStack(spacing: 10) {
            if let last = workoutManager.repResults.last {
                Image(systemName: last.type.icon)
                    .foregroundStyle(last.type.color)
                Text(last.feedbackMessage)
                    .fontWeight(.medium)
                Spacer()
                Text("Rep \(last.repNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Theme.brand)
                Text(workoutManager.lastFeedback)
                Spacer(minLength: 0)
            }
        }
        .cardStyle(padding: 14)
        .animation(.easeInOut, value: workoutManager.repResults.count)
    }

    // MARK: - Recent reps

    private var recentReps: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent reps")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(workoutManager.repResults.suffix(12).reversed()) { rep in
                        RepBadge(number: rep.repNumber, classification: rep.type)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
    }
}

#Preview {
    ActiveWorkoutView(onStop: {})
}
