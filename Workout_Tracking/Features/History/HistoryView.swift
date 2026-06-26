//
//  HistoryView.swift
//  Workout_Tracking
//
//  All saved sessions, grouped by day, with swipe-to-delete.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No history yet",
                        message: "Finished workouts will appear here so you can review your form over time."
                    )
                } else {
                    List {
                        ForEach(groupedSessions, id: \.title) { group in
                            Section(group.title) {
                                ForEach(group.sessions) { session in
                                    NavigationLink(value: session) {
                                        SessionRow(session: session)
                                    }
                                }
                                .onDelete { offsets in
                                    delete(group.sessions, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session)
            }
            .toolbar {
                if !sessions.isEmpty {
                    EditButton()
                }
            }
        }
    }

    // MARK: - Grouping

    private var groupedSessions: [(title: String, sessions: [WorkoutSession])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            (title: title(for: day), sessions: groups[day]!.sorted { $0.date > $1.date })
        }
    }

    private func title(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month().day())
    }

    private func delete(_ sessions: [WorkoutSession], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, RepRecord.self], inMemory: true)
}
