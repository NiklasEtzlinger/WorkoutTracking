//
//  RepClassification.swift
//  Workout_Tracking
//
//  Central, type-safe representation of the model's output classes.
//  Replaces scattered raw "correct" / "half_rom" / "too_fast" strings
//  with a single source of truth for labels, colors and icons.
//

import SwiftUI

enum RepClassification: String, CaseIterable, Codable {
    case correct
    case halfRom = "half_rom"
    case tooFast = "too_fast"
    case unknown

    init(raw: String) {
        self = RepClassification(rawValue: raw) ?? .unknown
    }

    /// Full, encouraging feedback line shown right after a rep.
    var feedback: String {
        switch self {
        case .correct: return "Perfect form!"
        case .halfRom: return "Go deeper — full range"
        case .tooFast: return "Slow it down"
        case .unknown: return "Rep counted"
        }
    }

    /// Compact label for badges, lists and charts.
    var shortLabel: String {
        switch self {
        case .correct: return "Correct"
        case .halfRom: return "Half ROM"
        case .tooFast: return "Too fast"
        case .unknown: return "Counted"
        }
    }

    var color: Color {
        switch self {
        case .correct: return Theme.correct
        case .halfRom: return Theme.halfRom
        case .tooFast: return Theme.tooFast
        case .unknown: return Theme.neutral
        }
    }

    var icon: String {
        switch self {
        case .correct: return "checkmark.circle.fill"
        case .halfRom: return "arrow.up.and.down.circle.fill"
        case .tooFast: return "hare.fill"
        case .unknown: return "circle.fill"
        }
    }

    var isCorrect: Bool { self == .correct }
}
