//
//  WorkoutSummaryView.swift
//  Workout_Tracking
//
//  Post-workout recap. Persists the finished session to SwiftData
//  exactly once, then lets the user dismiss the flow.
//

import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var workoutManager = WorkoutManager.shared

    let onClose: () -> Void

    @State private var didSave = false
    @State private var saveAttempted = false

    private var grades: Bool { workoutManager.currentExercise.supportsFormGrading }
    private var stats: WorkoutStats { workoutManager.stats }
    private var formPct: Double { stats.correctPercentage }
    private var hasReps: Bool { stats.totalReps > 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headline

                if hasReps {
                    hero
                    statsGrid
                    if grades { breakdown }
                } else {
                    EmptyStateView(
                        icon: "questionmark.circle",
                        title: "No reps detected",
                        message: "We didn't catch any reps this time, so nothing was saved. Make sure your watch is snug and try again."
                    )
                    .cardStyle()
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            GradientButton(title: "Done", systemImage: "checkmark", action: onClose)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
        }
        .onAppear(perform: saveIfNeeded)
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.gradient(for: hasReps ? Theme.correct : Theme.neutral))
                    .frame(width: 72, height: 72)
                Image(systemName: hasReps ? "checkmark" : "xmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: (hasReps ? Theme.correct : Theme.neutral).opacity(0.4), radius: 12, y: 6)

            Text(hasReps ? "Workout Complete!" : "Workout Ended")
                .font(.title2.weight(.bold))
            Text(workoutManager.currentExercise.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
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
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("Form score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 190, height: 190)
        } else {
            VStack(spacing: 2) {
                Text("\(stats.totalReps)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(workoutManager.currentExercise.tint)
                Text("total reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            StatCard(icon: "repeat", value: "\(stats.totalReps)", label: "Total reps", tint: Theme.brand)
            StatCard(icon: "clock.fill", value: durationString, label: "Duration", tint: Theme.accent)
            if grades {
                StatCard(icon: "checkmark.seal.fill", value: "\(stats.correctReps)", label: "Clean reps", tint: Theme.correct)
                StatCard(icon: "gauge.with.dots.needle.67percent", value: "\(Int(workoutManager.averageConfidence * 100))%", label: "Avg confidence", tint: Theme.halfRom)
            }
        }
    }

    // MARK: - Breakdown

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rep breakdown")
                .font(.headline)

            BreakdownRow(label: RepClassification.correct.shortLabel, count: stats.correctReps, total: stats.totalReps, color: Theme.correct)
            BreakdownRow(label: RepClassification.halfRom.shortLabel, count: stats.halfRomReps, total: stats.totalReps, color: Theme.halfRom)
            BreakdownRow(label: RepClassification.tooFast.shortLabel, count: stats.tooFastReps, total: stats.totalReps, color: Theme.tooFast)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var durationString: String {
        let total = Int(workoutManager.elapsedSeconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Persistence

    private func saveIfNeeded() {
        guard !saveAttempted else { return }
        saveAttempted = true
        guard hasReps else { return }

        let m = workoutManager
        let session = WorkoutSession(
            date: m.startDate,
            endDate: m.endDate,
            exercise: m.currentExercise,
            durationSeconds: m.elapsedSeconds,
            totalReps: m.stats.totalReps,
            correctReps: m.stats.correctReps,
            halfRomReps: m.stats.halfRomReps,
            tooFastReps: m.stats.tooFastReps,
            averageConfidence: m.averageConfidence
        )
        modelContext.insert(session)

        for rep in m.repResults {
            let record = RepRecord(
                repNumber: rep.repNumber,
                classification: rep.type,
                confidence: rep.confidence,
                timestamp: rep.timestamp
            )
            record.session = session
            modelContext.insert(record)
        }

        do {
            try modelContext.save()
            didSave = true
        } catch {
            print("Failed to save session: \(error)")
        }
    }
}

// MARK: - Breakdown row

private struct BreakdownRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var fraction: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .systemGray5))
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 8)
        }
    }
}
