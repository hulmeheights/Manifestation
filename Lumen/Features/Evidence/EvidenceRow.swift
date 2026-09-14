//
//  EvidenceRow.swift
//  Lumen
//

import SwiftUI

struct EvidenceRow: View {
    let entry: EvidenceEntry
    let intention: Intention?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.kind.tint.opacity(0.16))
                Image(systemName: entry.kind.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(entry.kind.tint)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.text)
                    .font(.body15)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(entry.kind.title)
                        .font(.tiny11)
                        .foregroundStyle(entry.kind.tint.opacity(0.9))

                    Text("·")
                        .font(.tiny11)
                        .foregroundStyle(Palette.faint)

                    Text("\(entry.date.relativeDayLabel), \(entry.date.timeOnly)")
                        .font(.tiny11)
                        .foregroundStyle(Palette.faint)
                }

                if let intention {
                    Text(intention.affirmation)
                        .font(.tiny11)
                        .foregroundStyle(Palette.muted.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
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
}
