//
//  Components.swift
//  Lumen
//
//  The small reusable pieces. Nothing here knows about the data model.
//

import SwiftUI

// MARK: - Cards

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    var radius: CGFloat = Metric.cardRadius
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1)
            )
    }
}

extension View {
    /// A soft coloured bloom behind an element.
    func glow(_ color: Color, radius: CGFloat = 18, opacity: Double = 0.5) -> some View {
        shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Headers

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.sectionLabel)
                .kerning(1.4)
                .foregroundStyle(Palette.faint)

            Spacer(minLength: 8)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.caption13)
                    .foregroundStyle(Palette.gold)
            }
        }
    }
}

// MARK: - Chips

struct Chip: View {
    let text: String
    var symbol: String? = nil
    var tint: Color = Palette.muted
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.tiny11)
        }
        .foregroundStyle(filled ? Palette.void : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)))
        )
        .overlay(
            Capsule().strokeBorder(tint.opacity(filled ? 0 : 0.28), lineWidth: 1)
        )
    }
}

struct SelectableChip: View {
    let text: String
    var symbol: String? = nil
    var tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Chip(text: text, symbol: symbol, tint: tint, filled: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rings

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 8
    var style: AnyShapeStyle = AnyShapeStyle(Grad.gold)
    var trackOpacity: Double = 0.10

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(trackOpacity), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(style, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}

/// Slow expand-and-contract, roughly a four-in / six-out breath.
struct BreathRing: View {
    var animated: Bool = true
    var color: Color = Palette.gold

    @State private var expanded = false

    var body: some View {
        Circle()
            .strokeBorder(color.opacity(0.22), lineWidth: 1.5)
            .background(Circle().fill(Grad.halo(color)).opacity(0.5))
            .scaleEffect(expanded ? 1.0 : 0.78)
            .opacity(expanded ? 0.9 : 0.5)
            .onAppear {
                guard animated else { return }
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    expanded = true
                }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Stats

struct StatTile: View {
    let value: String
    let label: String
    var symbol: String? = nil
    var tint: Color = Palette.gold

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(.numeral)
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.tiny11)
                .foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Metric.tileRadius, style: .continuous)
                .fill(Palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metric.tileRadius, style: .continuous)
                .strokeBorder(Palette.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Buttons

struct GoldButtonStyle: ButtonStyle {
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 15 : 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Palette.void)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Grad.gold)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var tint: Color = Palette.ink
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 15 : 16, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.raised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GoldButtonStyle {
    static var gold: GoldButtonStyle { GoldButtonStyle() }
    static var goldCompact: GoldButtonStyle { GoldButtonStyle(compact: true) }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
    static var ghostCompact: GhostButtonStyle { GhostButtonStyle(compact: true) }
}

// MARK: - Empty state

struct EmptyNote: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Palette.gold.opacity(0.8))
                .glow(Palette.gold, radius: 14, opacity: 0.35)

            Text(title)
                .font(.titleSerif)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body15)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.goldCompact)
                    .frame(maxWidth: 240)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Flow layout

/// Wraps subviews onto as many lines as they need. Used for the word-by-word
/// affirmation display and for chip rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 10
    var alignment: HorizontalAlignment = .center

    struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(maxWidth: CGFloat, subviews: Subviews) -> [Line] {
        var result: [Line] = []
        var current = Line()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projected = current.indices.isEmpty
                ? size.width
                : current.width + spacing + size.width

            if !current.indices.isEmpty && projected > maxWidth {
                result.append(current)
                current = Line(indices: [index], width: size.width, height: size.height)
            } else {
                current.indices.append(index)
                current.width = projected
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty { result.append(current) }
        return result
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let all = lines(maxWidth: maxWidth, subviews: subviews)
        let height = all.reduce(0) { $0 + $1.height }
            + lineSpacing * CGFloat(max(0, all.count - 1))
        let width = all.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let all = lines(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY

        for line in all {
            var x: CGFloat
            if alignment == .leading {
                x = bounds.minX
            } else if alignment == .trailing {
                x = bounds.maxX - line.width
            } else {
                x = bounds.minX + (bounds.width - line.width) / 2
            }
            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }
}

// MARK: - Text fields

struct WritingField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int> = 1...1

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .lineLimit(lineLimit)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundStyle(Palette.ink)
            .tint(Palette.gold)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Palette.stroke, lineWidth: 1)
            )
    }
}
