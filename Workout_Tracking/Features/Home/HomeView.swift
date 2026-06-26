//
//  HomeView.swift
//  Workout_Tracking
//
//  Dashboard: weekly goal, streak, quick-start and recent activity.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 4

    let startWorkout: () -> Void
    let showHistory: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard

                    GradientButton(title: "Start Workout", systemImage: "play.fill", action: startWorkout)

                    if sessions.isEmpty {
                        EmptyStateView(
                            icon: "bolt.heart.fill",
                            title: "Ready when you are",
                            message: "Put on your Apple Watch and start your first workout — your stats and progress will show up here."
                        )
                        .cardStyle()
                    } else {
                        statsGrid
                        recentSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(greeting)
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        HStack(spacing: 20) {
            ProgressRing(
                progress: Double(thisWeekCount) / Double(max(weeklyGoal, 1)),
                lineWidth: 11,
                color: .white,
                trackColor: .white.opacity(0.25)
            ) {
                VStack(spacing: 0) {
                    Text("\(thisWeekCount)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("of \(weeklyGoal)")
                        .font(.caption2)
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 6) {
                Text("This week")
                    .font(.headline)
                Text(weeklyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                Label("\(streak) day streak", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 2)
            }
            .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .cardStyle(padding: 20, fill: Theme.brandGradient)
        .shadow(color: Theme.brand.opacity(0.30), radius: 16, y: 8)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            StatCard(icon: "checkmark.seal.fill", value: "\(Int(avgForm))%", label: "Avg form", tint: Theme.correct)
            StatCard(icon: "repeat", value: "\(totalReps)", label: "Total reps", tint: Theme.brand)
            StatCard(icon: "figure.run", value: "\(sessions.count)", label: "Workouts", tint: Theme.accent)
            StatCard(icon: "flame.fill", value: "\(streak)", label: "Day streak", tint: Theme.halfRom)
        }
    }

    // MARK: - Recent

    private var recentSection: some View {
        let recent = Array(sessions.prefix(3))
        return VStack(spacing: 12) {
            SectionHeader(
                title: "Recent",
                actionTitle: sessions.count > 3 ? "See all" : nil,
                action: sessions.count > 3 ? showHistory : nil
            )
            VStack(spacing: 0) {
                ForEach(recent) { session in
                    NavigationLink(value: session) {
                        SessionRow(session: session)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    if session.id != recent.last?.id {
                        Divider()
                    }
                }
            }
            .cardStyle(padding: 14)
        }
    }

    // MARK: - Derived values

    private var thisWeekCount: Int { SessionAnalytics.sessionsThisWeek(sessions).count }
    private var streak: Int { SessionAnalytics.currentStreak(sessions) }
    private var totalReps: Int { SessionAnalytics.totalReps(sessions) }
    private var avgForm: Double { SessionAnalytics.averageFormScore(sessions) }

    private var weeklyMessage: String {
        let remaining = weeklyGoal - thisWeekCount
        if remaining <= 0 { return "Goal reached — nice work!" }
        return "\(remaining) more to hit your goal"
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Good night"
        }
    }
}

#Preview {
    HomeView(startWorkout: {}, showHistory: {})
        .modelContainer(for: [WorkoutSession.self, RepRecord.self], inMemory: true)
}
