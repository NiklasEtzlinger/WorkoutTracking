//
//  SessionAnalytics.swift
//  Workout_Tracking
//
//  Pure functions that derive stats/trends from saved sessions.
//  Shared by Home and Insights so the math lives in one place.
//

import Foundation

/// A single day bucket used by charts.
struct DayValue: Identifiable {
    let id = UUID()
    let date: Date
    let reps: Int
}

/// A single session's form score over time (for trend charts).
struct FormPoint: Identifiable {
    let id = UUID()
    let date: Date
    let formScore: Double
    let exercise: Exercise
}

/// Total reps grouped by exercise (for the breakdown chart).
struct ExerciseTotal: Identifiable {
    var id: Exercise { exercise }
    let exercise: Exercise
    let reps: Int
}

enum SessionAnalytics {

    // MARK: - Streak

    /// Number of consecutive days (ending today or yesterday) with ≥1 session.
    static func currentStreak(
        _ sessions: [WorkoutSession],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let days = Set(sessions.map { calendar.startOfDay(for: $0.date) })

        var day = calendar.startOfDay(for: now)
        // Not having worked out *yet today* shouldn't break a streak.
        if !days.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  days.contains(yesterday) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    // MARK: - This week

    static func sessionsThisWeek(
        _ sessions: [WorkoutSession],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [WorkoutSession] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        return sessions.filter { $0.date >= weekStart }
    }

    // MARK: - Totals

    static func totalReps(_ sessions: [WorkoutSession]) -> Int {
        sessions.reduce(0) { $0 + $1.totalReps }
    }

    /// Reps-weighted correct percentage across exercises that grade form.
    static func averageFormScore(_ sessions: [WorkoutSession]) -> Double {
        let graded = sessions.filter { $0.exercise.supportsFormGrading }
        let total = graded.reduce(0) { $0 + $1.totalReps }
        guard total > 0 else { return 0 }
        let correct = graded.reduce(0) { $0 + $1.correctReps }
        return Double(correct) / Double(total) * 100
    }

    static func bestFormScore(_ sessions: [WorkoutSession]) -> Double {
        sessions
            .filter { $0.exercise.supportsFormGrading && $0.totalReps > 0 }
            .map(\.formScore)
            .max() ?? 0
    }

    static func mostReps(_ sessions: [WorkoutSession]) -> Int {
        sessions.map(\.totalReps).max() ?? 0
    }

    // MARK: - Trends

    /// Reps summed per calendar day for the last `days` days (including empty days).
    static func repsPerDay(
        _ sessions: [WorkoutSession],
        days: Int,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [DayValue] {
        let today = calendar.startOfDay(for: now)
        var buckets: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            buckets[day, default: 0] += session.totalReps
        }
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayValue(date: day, reps: buckets[day] ?? 0)
        }
    }

    /// Form score per graded session, oldest → newest.
    static func formTrend(_ sessions: [WorkoutSession]) -> [FormPoint] {
        sessions
            .filter { $0.exercise.supportsFormGrading && $0.totalReps > 0 }
            .sorted { $0.date < $1.date }
            .map { FormPoint(date: $0.date, formScore: $0.formScore, exercise: $0.exercise) }
    }

    /// Total reps grouped by exercise (for a breakdown chart).
    static func repsByExercise(_ sessions: [WorkoutSession]) -> [ExerciseTotal] {
        var buckets: [Exercise: Int] = [:]
        for session in sessions {
            buckets[session.exercise, default: 0] += session.totalReps
        }
        return buckets
            .map { ExerciseTotal(exercise: $0.key, reps: $0.value) }
            .sorted { $0.reps > $1.reps }
    }
}
