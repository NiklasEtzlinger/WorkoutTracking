//
//  ExercisePickerView.swift
//  Workout_Tracking
//
//  First step of the workout flow: choose what to train.
//

import SwiftUI

struct ExercisePickerView: View {
    @EnvironmentObject private var connectivity: PhoneConnectivityManager
    let onSelect: (Exercise) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Choose an exercise")
                        .font(.title2.weight(.bold))
                    Text("Forma grades every rep on-device and saves your session.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                .padding(.horizontal)

                ForEach(Exercise.allCases) { exercise in
                    ExerciseCard(exercise: exercise) { onSelect(exercise) }
                        .disabled(!connectivity.isWatchReachable)
                        .opacity(connectivity.isWatchReachable ? 1 : 0.5)
                }

                if !connectivity.isWatchReachable {
                    Label("Open Forma on your Apple Watch to begin", systemImage: "applewatch.slash")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
    }
}

private struct ExerciseCard: View {
    let exercise: Exercise
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(exercise.gradient)
                        .frame(width: 62, height: 62)
                    Image(systemName: exercise.iconName)
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(exercise.displayName)
                            .font(.headline)
                        if exercise.isBeta { TagPill(text: "Beta") }
                    }
                    Text(exercise.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
