//
//  MoonwritLiveActivity.swift
//  MoonwritWidget
//
//  The card you push live. Lock screen, banner-over-the-top-of-everything,
//  and the Dynamic Island on the phones that have one.
//
//  Drawn in the night palette always: it lives on the lock screen, which is
//  dark, and it is the one surface where the moon is allowed to glow.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MoonwritLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MoonwritAttributes.self) { context in

            // MARK: Lock screen / banner
            LiveCard(context: context)
                .activityBackgroundTint(Color(red: 0.027, green: 0.031, blue: 0.047))
                .activitySystemActionForegroundColor(Color(red: 0.94, green: 0.93, blue: 0.90))

        } dynamicIsland: { context in

            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MoonDisc(fraction: context.state.moonFraction, size: 34)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.repsToday)/\(context.state.repsTarget)")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.line)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(3)
                }
            } compactLeading: {
                MoonDisc(fraction: context.state.moonFraction, size: 18)
            } compactTrailing: {
                Text("\(context.state.repsToday)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
            } minimal: {
                MoonDisc(fraction: context.state.moonFraction, size: 18)
            }
            .keylineTint(Color(red: 0.94, green: 0.93, blue: 0.90))
        }
    }
}

// MARK: - The card itself

private struct LiveCard: View {

    let context: ActivityViewContext<MoonwritAttributes>

    private var ink: Color { Color(red: 0.94, green: 0.93, blue: 0.90) }
    private var dim: Color { ink.opacity(0.55) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            VStack(spacing: 8) {
                MoonDisc(fraction: context.state.moonFraction, size: 44)
                if context.attributes.shape == .session {
                    Text("\(context.state.repsToday)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(ink)
                }
            }

            VStack(alignment: .leading, spacing: 8) {

                Text(eyebrow.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.6)
                    .foregroundStyle(dim)

                Text(context.attributes.line.isEmpty ? "Write it tonight." : context.attributes.line)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if context.attributes.shape == .session {
                    progressTrack
                } else if !context.state.note.isEmpty {
                    Text(context.state.note)
                        .font(.system(size: 12))
                        .foregroundStyle(dim)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var eyebrow: String {
        if context.attributes.shape == .session {
            return context.state.windowTitle.isEmpty
                ? "Writing"
                : "\(context.state.windowTitle) · \(context.state.repsToday) of \(context.state.repsTarget)"
        }
        return context.state.windowTitle.isEmpty ? "Held" : "\(context.state.windowTitle) window open"
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(ink.opacity(0.14))
                Capsule()
                    .fill(ink)
                    .frame(width: max(3, geo.size.width * context.state.progress))
            }
        }
        .frame(height: 3)
    }
}
