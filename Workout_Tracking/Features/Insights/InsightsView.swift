//
//  InsightsView.swift
//  Workout_Tracking
//
//  Aggregate progress across all saved sessions, visualised with
//  Swift Charts.
//

import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "No insights yet",
                        message: "Once you've logged a few workouts, your trends and records will show up here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            totals
                            repsPerDayCard
                            formTrendCard
                            byExerciseCard
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Totals

    private var totals: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            StatCard(icon: "figure.run", value: "\(sessions.count)", label: "Workouts", tint: Theme.brand)
            StatCard(icon: "repeat", value: "\(SessionAnalytics.totalReps(sessions))", label: "Total reps", tint: Theme.accent)
            StatCard(icon: "rosette", value: "\(Int(SessionAnalytics.bestFormScore(sessions)))%", label: "Best form", tint: Theme.correct)
            StatCard(icon: "flame.fill", value: "\(SessionAnalytics.currentStreak(sessions))", label: "Day streak", tint: Theme.halfRom)
        }
    }

    // MARK: - Reps per day

    private var repsPerDayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reps · last 30 days")
                .font(.headline)
            Chart(SessionAnalytics.repsPerDay(sessions, days: 30)) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Reps", day.reps)
                )
                .foregroundStyle(Theme.brandGradient)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Form trend

    private var formTrendCard: some View {
        let trend = SessionAnalytics.formTrend(sessions)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Form score trend")
                .font(.headline)
            if trend.count < 2 {
                Text("Complete a few more graded workouts to reveal your trend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24)
            } else {
                Chart(trend) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Form", point.formScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.brand.opacity(0.25), Theme.brand.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Form", point.formScore)
                    )
                    .foregroundStyle(Theme.brand)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Form", point.formScore)
                    )
                    .foregroundStyle(Theme.color(forFormScore: point.formScore))
                }
                .chartYScale(domain: 0.0...100.0)
                .frame(height: 180)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - By exercise

    private var byExerciseCard: some View {
        let totals = SessionAnalytics.repsByExercise(sessions)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Reps by exercise")
                .font(.headline)
            Chart(totals) { item in
                BarMark(
                    x: .value("Reps", item.reps),
                    y: .value("Exercise", item.exercise.displayName)
                )
                .foregroundStyle(item.exercise.tint)
                .cornerRadius(5)
                .annotation(position: .trailing) {
                    Text("\(item.reps)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(totals.count) * 46 + 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [WorkoutSession.self, RepRecord.self], inMemory: true)
}
