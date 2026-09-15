//
//  MoonwritRoot.swift
//  Lumen
//
//  The new shell: four tabs, drawn rather than using the system bar, so the
//  night face stays intact.
//

import SwiftUI

enum MoonwritTab: String, CaseIterable, Identifiable {
    case today, cycle, evidence, you

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:    return "Today"
        case .cycle:    return "Cycle"
        case .evidence: return "Proof"
        case .you:      return "You"
        }
    }

    var symbol: String {
        switch self {
        case .today:    return "pencil.line"
        case .cycle:    return "moon.stars"
        case .evidence: return "sparkles"
        case .you:      return "person"
        }
    }
}

struct MoonwritRoot: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @State private var tab: MoonwritTab = .today
    @State private var ritual: RitualLaunch?

    private var skin: Skin { store.skin }

    var body: some View {
        ZStack {
            NightGround()

            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .today:    TodayScreen(launch: $ritual)
                    case .cycle:    CycleScreen()
                    case .evidence: ProofScreen()
                    case .you:      YouScreen()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                MoonwritTabBar(selection: $tab)
            }
        }
        .skin(skin)
        .fullScreenCover(item: $ritual) { launch in
            RitualScreen(intention: launch.intention, window: launch.window)
                .skin(skin)
        }
        .task { store.publishSnapshot() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.publishSnapshot() }
        }
    }
}

// MARK: - The bar

private struct MoonwritTabBar: View {
    @Binding var selection: MoonwritTab
    @Environment(\.skin) private var skin

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MoonwritTab.allCases) { item in
                Button {
                    selection = item
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 17, weight: .medium))
                        Text(item.title.uppercased())
                            .font(Ink.mono(9, weight: .semibold))
                            .kerning(1.1)
                    }
                    .foregroundStyle(selection == item ? skin.ink : skin.dim)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selection == item ? [.isSelected] : [])
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background(alignment: .top) {
            Rectangle()
                .fill(skin.hairline)
                .frame(height: 1)
        }
    }
}

// MARK: - Today

struct TodayScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    @Binding var launch: RitualLaunch?
    @State private var writingLine = false

    private var moon: MoonMoment { store.moon }
    private var focus: Intention? { store.focusIntention }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                if let focus {
                    lineBlock(focus)
                    windows
                    beginButton(focus)
                } else {
                    emptyBlock
                }

                if store.evidenceThisChapter > 0, let latest = store.evidence.first {
                    proofPeek(latest)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $writingLine) {
            IntentionEditorView(existing: nil)
        }
    }

    // MARK: Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                MoonDisc(fraction: moon.progress, size: 22)
                Text("\(moon.phase.title) · day \(moon.cycleDay)".uppercased())
                    .font(Ink.label)
                    .kerning(1.6)
                    .foregroundStyle(skin.dim)
            }
            .padding(.top, 14)

            Text(headline)
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .padding(.top, 20)
                .fixedSize(horizontal: false, vertical: true)

            Text(store.suggestedWindow.instruction)
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headline: String {
        let nights = moon.nightsToFull
        if moon.phase == .fullMoon { return "Look what\nmoved." }
        if nights > 0 && nights <= 5 {
            return nights == 1 ? "One night\nto full." : "\(nights) nights\nto full."
        }
        return Library.greeting(name: store.profile.name)
    }

    private func lineBlock(_ intention: Intention) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "In the light", trailing: intention.charge.title)
                .padding(.bottom, 12)

            Text(intention.affirmation)
                .font(Ink.line)
                .foregroundStyle(skin.ink)
                .fixedSize(horizontal: false, vertical: true)

            Meter(progress: intention.chargeProgress)
                .padding(.top, 16)

            HStack {
                Text("\(intention.reps) reps")
                Spacer()
                if let next = intention.charge.next {
                    Text("\(next.threshold) → \(next.title.lowercased())")
                }
            }
            .font(Ink.tiny)
            .kerning(1.1)
            .foregroundStyle(skin.dim)
            .padding(.top, 7)
        }
        .padding(.top, Space.section)
    }

    private var windows: some View {
        HStack(spacing: 7) {
            ForEach(RitualWindow.allCases) { window in
                WindowTile(
                    window: window,
                    done: store.repsCompleted(in: window),
                    live: store.suggestedWindow == window
                )
            }
        }
        .padding(.top, 22)
    }

    private func beginButton(_ intention: Intention) -> some View {
        let window = store.suggestedWindow
        let left = max(0, window.reps - store.repsCompleted(in: window))

        return Button {
            launch = RitualLaunch(intention: intention, window: window)
        } label: {
            Text(left == 0 ? "All three windows done" : "Write it \(left) more \(left == 1 ? "time" : "times")")
        }
        .buttonStyle(.ink)
        .disabled(left == 0)
        .opacity(left == 0 ? 0.45 : 1)
        .padding(.top, 20)
    }

    private var emptyBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Library.noIntentions)
                .font(Ink.body(16))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            Button("Write your line") { writingLine = true }
                .buttonStyle(.ink)
        }
        .padding(.top, Space.section)
    }

    private func proofPeek(_ entry: EvidenceEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "This chapter", trailing: "\(store.evidenceThisChapter)")
            Text(entry.text)
                .font(Ink.body(15))
                .foregroundStyle(skin.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(entry.kind.title) · \(entry.date.relativeDayLabel)".uppercased())
                .font(Ink.tiny)
                .kerning(1.3)
                .foregroundStyle(skin.evidence)
        }
        .padding(.top, Space.section)
        .padding(.bottom, 4)
        .overlay(alignment: .top) {
            Rectangle().fill(skin.hairline).frame(height: 1).padding(.top, 18)
        }
    }
}

// MARK: - A window tile

private struct WindowTile: View {
    let window: RitualWindow
    let done: Int
    let live: Bool

    @Environment(\.skin) private var skin

    private var complete: Bool { done >= window.reps }

    var body: some View {
        VStack(spacing: 6) {
            Text(complete ? "\(window.reps)" : "\(done)/\(window.reps)")
                .font(Ink.mono(15, weight: .semibold))
            Text(window.title.uppercased())
                .font(Ink.mono(9, weight: .semibold))
                .kerning(1.1)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(live ? skin.ground : skin.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                .fill(live ? skin.ink : skin.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                .strokeBorder(live ? Color.clear : skin.hairline, lineWidth: 1)
        )
        .opacity(complete && !live ? 0.55 : 1)
        .accessibilityElement(children: .combine)
    }
}
