//
//  CycleScreen.swift
//  Lumen
//
//  Where you are in the twenty-nine days, what the app is asking of you, and
//  the chapters behind you. Nothing here is a streak and nothing goes down.
//

import SwiftUI

struct CycleScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    private var moon: MoonMoment { store.moon }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                MoonDisc(fraction: moon.progress, size: 168)
                    .padding(.top, 30)

                Text(moon.phase.title)
                    .font(Ink.heading)
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 34)

                Text("Chapter \(chapterNumber) · day \(moon.cycleDay) of \(moon.cycleDays) · \(moon.illuminationPercent)% lit".uppercased())
                    .font(Ink.label)
                    .kerning(1.5)
                    .foregroundStyle(skin.dim)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                Text(moon.instruction)
                    .font(Ink.body(15))
                    .foregroundStyle(skin.dim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)
                    .padding(.horizontal, 12)

                phaseStrip
                    .padding(.top, 26)

                chapters
                    .padding(.top, 28)

                stageCard
                    .padding(.top, 26)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
    }

    private var chapterNumber: Int {
        let days = Date().timeIntervalSince(store.profile.startedAt) / 86_400
        return max(1, Int(days / MoonPhase.synodicMonth) + 1)
    }

    // MARK: The eight phases, with tonight marked

    private var phaseStrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(stride(from: 0.0, to: 1.0, by: 0.125)), id: \.self) { point in
                let isNow = abs(point - nearestEighth) < 0.001
                MoonDisc(fraction: point, size: 17, glowing: false)
                    .padding(4)
                    .overlay(
                        Circle()
                            .strokeBorder(isNow ? skin.ink : Color.clear, lineWidth: 1.5)
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) { Rectangle().fill(skin.hairline).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(skin.hairline).frame(height: 1) }
    }

    private var nearestEighth: Double {
        (moon.progress * 8).rounded(.down) / 8
    }

    // MARK: Chapters behind you

    private var chapters: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Chapters", trailing: "\(store.totalReps) reps in all")

            let all = store.recentChapters(3)
            let peak = max(1, all.map(\.reps).max() ?? 1)

            ForEach(all) { chapter in
                HStack(spacing: 12) {
                    Text(chapter.label)
                        .font(Ink.mono(10, weight: .semibold))
                        .foregroundStyle(skin.dim)
                        .frame(width: 34, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(skin.track)
                            Capsule()
                                .fill(skin.ink)
                                .frame(width: geo.size.width * Double(chapter.reps) / Double(peak))
                        }
                    }
                    .frame(height: 7)

                    Text("\(chapter.reps)")
                        .font(Ink.mono(11, weight: .semibold))
                        .foregroundStyle(skin.ink)
                        .monospacedDigit()
                        .frame(width: 38, alignment: .trailing)
                }
            }
        }
    }

    // MARK: What this phase asks

    private var stageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(moon.stage.verbLabel.uppercased())
                .font(Ink.tiny)
                .kerning(1.8)
                .foregroundStyle(skin.evidence)

            Text(moon.stage.title)
                .font(Ink.title(19))
                .foregroundStyle(skin.ink)

            Text(moon.stage.blurb)
                .font(Ink.body(14))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                .strokeBorder(skin.hairline, lineWidth: 1)
        )
    }
}

private extension CycleStage {
    var verbLabel: String {
        switch self {
        case .plant:   return "Plant"
        case .build:   return "Build"
        case .press:   return "Press"
        case .read:    return "Read"
        case .thank:   return "Thank"
        case .release: return "Hands off"
        }
    }
}

// MARK: - Proof

struct ProofScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    @State private var composing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    MoonDisc(fraction: store.moon.progress, size: 22)
                    Text("\(store.evidenceCount) since \(store.profile.startedAt.shortDay)".uppercased())
                        .font(Ink.label)
                        .kerning(1.6)
                        .foregroundStyle(skin.dim)
                }
                .padding(.top, 14)

                Text("What came\nback.")
                    .font(Ink.hero)
                    .foregroundStyle(skin.ink)
                    .padding(.top, 20)

                if store.evidence.isEmpty {
                    Text(Library.noEvidence)
                        .font(Ink.body(16))
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 22)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.evidence) { entry in
                            ProofRow(entry: entry)
                        }
                    }
                    .padding(.top, 20)
                }

                Button("Something showed up") { composing = true }
                    .buttonStyle(.ink)
                    .padding(.top, 26)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $composing) {
            EvidenceComposer()
        }
    }
}

private struct ProofRow: View {
    let entry: EvidenceEntry
    @Environment(\.skin) private var skin

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(entry.kind.title) · \(entry.date.relativeDayLabel)".uppercased())
                .font(Ink.tiny)
                .kerning(1.4)
                .foregroundStyle(skin.evidence)

            Text(entry.text)
                .font(Ink.body(15))
                .foregroundStyle(skin.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }
}
