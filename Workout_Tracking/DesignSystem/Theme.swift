//
//  Theme.swift
//  Workout_Tracking
//
//  Central design tokens: colors, gradients, radii and reusable
//  styling modifiers. Everything visual references this file so the
//  look can be retuned in one place.
//

import SwiftUI

enum Theme {
    // MARK: - Brand
    static let brand = Color(red: 0.36, green: 0.36, blue: 0.93)          // indigo
    static let brandSecondary = Color(red: 0.56, green: 0.36, blue: 0.95) // violet
    static let accent = Color(red: 1.00, green: 0.46, blue: 0.36)         // coral

    // MARK: - Semantic (rep quality)
    static let correct = Color(red: 0.18, green: 0.80, blue: 0.55)        // emerald
    static let halfRom = Color(red: 0.98, green: 0.67, blue: 0.22)        // amber
    static let tooFast = Color(red: 0.97, green: 0.37, blue: 0.43)        // rose
    static let neutral = Color(.systemGray)

    // MARK: - Gradients
    static let brandGradient = LinearGradient(
        colors: [brand, brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func gradient(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Traffic-light color for a 0–100 form score.
    static func color(forFormScore score: Double) -> Color {
        switch score {
        case 80...:    return correct
        case 50..<80:  return halfRom
        default:       return tooFast
        }
    }

    // MARK: - Metrics
    static let cardRadius: CGFloat = 22
    static let smallRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
}

// MARK: - Card styling

extension Theme {
    /// Default card surface color (adapts to light/dark mode).
    static let cardSurface = Color(uiColor: .secondarySystemBackground)
}

private struct CardModifier<S: ShapeStyle>: ViewModifier {
    var padding: CGFloat
    var fill: S

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(fill)
            )
    }
}

extension View {
    /// Standard card surface (rounded, filled with the secondary system color).
    func cardStyle(padding: CGFloat = Theme.cardPadding) -> some View {
        modifier(CardModifier(padding: padding, fill: Theme.cardSurface))
    }

    /// Card surface with a custom fill (e.g. a tinted gradient hero card).
    func cardStyle<S: ShapeStyle>(padding: CGFloat = Theme.cardPadding, fill: S) -> some View {
        modifier(CardModifier(padding: padding, fill: fill))
    }
}
