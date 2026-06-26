//
//  WorkoutSession.swift
//  Workout_Tracking
//
//  A persisted workout. Created on the summary screen once a live
//  workout ends, then surfaced in History and Insights.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var endDate: Date?
    /// Stored Exercise identifier (see `Exercise.from(id:)`).
    var exerciseID: String = Exercise.bicepCurl.rawValue
    var durationSeconds: Double = 0

    var totalReps: Int = 0
    var correctReps: Int = 0
    var halfRomReps: Int = 0
    var tooFastReps: Int = 0
    var averageConfidence: Double = 0

    @Relationship(deleteRule: .cascade, inverse: \RepRecord.session)
    var reps: [RepRecord] = []

    init(
        date: Date,
        endDate: Date?,
        exercise: Exercise,
        durationSeconds: Double,
        totalReps: Int,
        correctReps: Int,
        halfRomReps: Int,
        tooFastReps: Int,
        averageConfidence: Double,
        reps: [RepRecord] = []
    ) {
        self.id = UUID()
        self.date = date
        self.endDate = endDate
        self.exerciseID = exercise.rawValue
        self.durationSeconds = durationSeconds
        self.totalReps = totalReps
        self.correctReps = correctReps
        self.halfRomReps = halfRomReps
        self.tooFastReps = tooFastReps
        self.averageConfidence = averageConfidence
        self.reps = reps
    }

    // MARK: - Derived values

    var exercise: Exercise { Exercise.from(id: exerciseID) }

    /// Percentage of reps classified as correct (0–100).
    var formScore: Double {
        guard totalReps > 0 else { return 0 }
        return Double(correctReps) / Double(totalReps) * 100
    }

    var mistakeReps: Int { halfRomReps + tooFastReps }

    var formattedDuration: String {
        let total = Int(durationSeconds.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
