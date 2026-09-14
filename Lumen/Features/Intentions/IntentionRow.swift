//
//  IntentionRow.swift
//  Lumen
//

import SwiftUI

struct IntentionRow: View {
    let intention: Intention

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(intention.area.tint.opacity(0.16))
                Image(systemName: intention.area.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(intention.area.tint)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if intention.isFocus {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Palette.gold)
                    }
                    Text(intention.affirmation)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 8) {
                    Text(intention.charge.title)
                        .font(.tiny11)
                        .foregroundStyle(Palette.gold.opacity(0.9))

                    Text("·")
                        .font(.tiny11)
                        .foregroundStyle(Palette.faint)

                    Text(intention.reps.repsLabel)
                        .font(.tiny11)
                        .foregroundStyle(Palette.faint)

                    if intention.stage == .received {
                        Chip(text: "Received", symbol: "checkmark.seal.fill", tint: Palette.mint)
                    }
                }

                chargeBar
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Palette.faint)
        }
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

    private var chargeBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(intention.area.tint.opacity(0.85))
                    .frame(width: max(4, proxy.size.width * intention.chargeProgress))
            }
        }
        .frame(height: 4)
    }
}
