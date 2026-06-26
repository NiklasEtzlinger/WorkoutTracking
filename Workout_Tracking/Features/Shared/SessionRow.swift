//
//  SessionRow.swift
//  Workout_Tracking
//
//  Compact one-line summary of a saved session, shared by Home & History.
//

import SwiftUI

struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(session.exercise.tint.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: session.exercise.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(session.exercise.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.exercise.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if session.exercise.supportsFormGrading {
                    Text("\(Int(session.formScore))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.color(forFormScore: session.formScore))
                    Text("\(session.totalReps) reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(session.totalReps)")
                        .font(.subheadline.weight(.bold))
                    Text("reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }
}
