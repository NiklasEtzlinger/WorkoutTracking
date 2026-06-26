//
//  Exercise.swift
//  Workout_Tracking
//
//  Generic, extensible description of a trackable exercise.
//  Adding a new exercise is as simple as adding a case here.
//

import SwiftUI

enum Exercise: String, CaseIterable, Identifiable, Codable {
    case bicepCurl
    case pushUp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bicepCurl: return "Biceps Curl"
        case .pushUp:    return "Push-Up"
        }
    }

    /// Short marketing-style subtitle shown on cards.
    var subtitle: String {
        switch self {
        case .bicepCurl: return "Live AI form grading"
        case .pushUp:    return "Rep counting"
        }
    }

    var iconName: String {
        switch self {
        case .bicepCurl: return "dumbbell.fill"
        case .pushUp:    return "figure.core.training"
        }
    }

    /// Whether the on-device model grades each rep's form
    /// (vs. simply counting reps).
    var supportsFormGrading: Bool {
        switch self {
        case .bicepCurl: return true
        case .pushUp:    return false
        }
    }

    /// Experimental exercises get a small "Beta" tag in the UI.
    var isBeta: Bool { !supportsFormGrading }

    var tint: Color {
        switch self {
        case .bicepCurl: return Theme.brand
        case .pushUp:    return Theme.accent
        }
    }

    /// A pleasing two-stop gradient used for hero elements.
    var gradient: LinearGradient {
        LinearGradient(
            colors: [tint, tint.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Resolve a stored `exerciseID` back into an `Exercise`,
    /// defaulting to biceps curl for forward-compatibility.
    static func from(id: String) -> Exercise {
        Exercise(rawValue: id) ?? .bicepCurl
    }
}
