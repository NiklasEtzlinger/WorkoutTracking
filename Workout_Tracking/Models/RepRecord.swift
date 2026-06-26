//
//  RepRecord.swift
//  Workout_Tracking
//
//  A single persisted repetition belonging to a WorkoutSession.
//

import Foundation
import SwiftData

@Model
final class RepRecord {
    var id: UUID = UUID()
    var repNumber: Int = 0
    /// Raw classification string ("correct" / "half_rom" / "too_fast").
    var classificationRaw: String = RepClassification.unknown.rawValue
    var confidence: Double = 0
    var timestamp: Date = Date()

    var session: WorkoutSession?

    init(
        repNumber: Int,
        classification: RepClassification,
        confidence: Double,
        timestamp: Date
    ) {
        self.id = UUID()
        self.repNumber = repNumber
        self.classificationRaw = classification.rawValue
        self.confidence = confidence
        self.timestamp = timestamp
    }

    var classification: RepClassification {
        RepClassification(raw: classificationRaw)
    }

    var isCorrect: Bool { classification.isCorrect }
}
