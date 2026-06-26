//
//  SessionDetailView.swift
//  Workout_Tracking
//
//  Deep dive into one saved session: score, breakdown, per-rep chart
//  and the full rep-by-rep log.
//

import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: WorkoutSession

    private var grades: Bool { session.exercise.supportsFormGrading }
    private var sortedReps: [RepRecord] {
        session.reps.sorted { $0.repNumber < $1.repNumber }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                hero
                statsGrid
                if grades { breakdown }
                if grades && !sortedReps.isEmpty { repChart }
                if !sortedReps.isEmpty { repLog }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.exercise.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(session.exercise.gradient)
                    .frame(width: 56, height: 56)
                Image(systemName: session.exercise.iconName)
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(session.date.formatted(date: .complete, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                Text(session.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    // MARK: - Hero

    @ViewBuilder private var hero: some View {
        if grades {
            ProgressRing(
                progress: session.formScore / 100,
                lineWidth: 16,
                color: Theme.color(forFormScore: session.formScore)
            ) {
                VStack(spacing: 2) {
                    Text("\(Int(session.formScore))%")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text("Form score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            StatCard(icon: "repeat", value: "\(session.totalReps)", label: "Total reps", tint: Theme.brand)
            StatCard(icon: "clock.fill", value: session.formattedDuration, label: "Duration", tint: Theme.accent)
            if grades {
                StatCard(icon: "checkmark.seal.fill", value: "\(session.correctReps)", label: "Clean reps", tint: Theme.correct)
                StatCard(icon: "gauge.with.dots.needle.67percent", value: "\(Int(session.averageConfidence * 100))%", label: "Avg confidence", tint: Theme.halfRom)
            }
        }
    }

    // MARK: - Breakdown

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rep breakdown")
                .font(.headline)
            DetailBreakdownRow(label: RepClassification.correct.shortLabel, count: session.correctReps, total: session.totalReps, color: Theme.correct)
            DetailBreakdownRow(label: RepClassification.halfRom.shortLabel, count: session.halfRomReps, total: session.totalReps, color: Theme.halfRom)
            DetailBreakdownRow(label: RepClassification.tooFast.shortLabel, count: session.tooFastReps, total: session.totalReps, color: Theme.tooFast)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Per-rep chart

    private var repChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confidence per rep")
                .font(.headline)
            Chart(sortedReps) { rep in
                BarMark(
                    x: .value("Rep", rep.repNumber),
                    y: .value("Confidence", rep.confidence * 100)
                )
                .foregroundStyle(rep.classification.color)
                .cornerRadius(3)
            }
            .chartYScale(domain: 0.0...100.0)
            .chartYAxis {
                AxisMarks(values: [0.0, 50.0, 100.0]) { value in
                    AxisGridLine()
                    AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int(v))%") } }
                }
            }
            .frame(height: 170)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Rep log

    private var repLog: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rep log")
                .font(.headline)
                .padding(.bottom, 6)
            ForEach(sortedReps) { rep in
                HStack {
                    Text("Rep \(rep.repNumber)")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if grades {
                        Text("\(Int(rep.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Label(rep.classification.shortLabel, systemImage: rep.classification.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(rep.classification.color)
                        .labelStyle(.titleAndIcon)
                }
                .padding(.vertical, 9)
                if rep.id != sortedReps.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct DetailBreakdownRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var fraction: Double { total > 0 ? Double(count) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(uiColor: .systemGray5))
                    Capsule().fill(color).frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 8)
        }
    }
}
