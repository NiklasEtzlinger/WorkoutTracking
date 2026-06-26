//
//  Components.swift
//  Workout_Tracking
//
//  Small, reusable building blocks shared across screens.
//

import SwiftUI

// MARK: - Progress Ring

struct ProgressRing<Content: View>: View {
    var progress: Double            // 0...1
    var lineWidth: CGFloat = 14
    var color: Color = Theme.brand
    var trackColor: Color = Color(uiColor: .systemGray5)
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(
                    Theme.gradient(for: color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            content()
        }
    }
}

extension ProgressRing where Content == EmptyView {
    init(
        progress: Double,
        lineWidth: CGFloat = 14,
        color: Color = Theme.brand,
        trackColor: Color = Color(.systemGray5)
    ) {
        self.init(progress: progress, lineWidth: lineWidth, color: color, trackColor: trackColor) {
            EmptyView()
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var tint: Color = Theme.brand

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Inline metric (used inside hero cards / live workout)

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.semibold))
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.medium))
            }
        }
    }
}

// MARK: - Gradient Button

struct GradientButton: View {
    let title: String
    var systemImage: String? = nil
    var gradient: LinearGradient = Theme.brandGradient
    var shadowColor: Color = Theme.brand
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(gradient, in: RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
            .shadow(color: shadowColor.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Pill (e.g. "BETA")

struct TagPill: View {
    let text: String
    var color: Color = Theme.accent

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - Rep Badge (classification-aware)

struct RepBadge: View {
    let number: Int
    let classification: RepClassification

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: classification.isCorrect ? "checkmark" : "xmark")
                .font(.caption.weight(.bold))
            Text("\(number)")
                .font(.caption2)
        }
        .frame(width: 40, height: 40)
        .background(classification.color.opacity(0.18), in: Circle())
        .foregroundStyle(classification.color)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(Theme.brandGradient)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
    }
}

// MARK: - Connection status chip

struct ConnectionChip: View {
    let isConnected: Bool
    var connectedText: String = "Watch connected"
    var disconnectedText: String = "Watch not connected"

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? Theme.correct : Theme.tooFast)
                .frame(width: 8, height: 8)
            Text(isConnected ? connectedText : disconnectedText)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
