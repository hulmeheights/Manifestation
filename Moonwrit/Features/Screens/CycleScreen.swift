//
//  CycleScreen.swift
//  Moonwrit
//
//  The moon guide. Not a phase read-out — an answer to "what do I do tonight,
//  and what am I waiting for".
//
//  Everything here recomputes from the current date every time the screen is
//  drawn, so it is never stale and never needs a refresh or a network call.
//

import SwiftUI

struct CycleScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    @State private var expanded: String?

    private var moon: MoonMoment { store.moon }
    private var focus: Intention? { store.focusIntention }
    private var guidance: NightGuidance { moon.guidance(for: focus) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                head
                monthStrip.padding(.top, 26)
                tonight.padding(.top, 26)
                nextBig.padding(.top, 14)
                theMap.padding(.top, Space.section)
                coming.padding(.top, Space.section)
                chapters.padding(.top, Space.section)
                honesty.padding(.top, Space.section)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - The moon itself

    private var head: some View {
        VStack(spacing: 0) {
            MoonDisc(fraction: moon.progress, size: 158)
                .padding(.top, 24)

            Text(tonightName)
                .font(Ink.heading)
                .foregroundStyle(skin.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 28)

            Text("\(moon.illuminationPercent)% lit · \(moon.isWaxing ? "growing" : "fading") · day \(moon.cycleDay) of \(moon.cycleDays)".uppercased())
                .font(Ink.label)
                .kerning(1.5)
                .foregroundStyle(skin.dim)
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            Text("Chapter \(chapterNumber) · \(store.repsThisChapter) reps and \(store.evidenceThisChapter) \(store.evidenceThisChapter == 1 ? "sign" : "signs") so far")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
    }

    private var tonightName: String {
        if let night = MoonAlmanac.tonight() { return night.title }
        return moon.phase.title
    }

    private var chapterNumber: Int {
        let days = Date().timeIntervalSince(store.profile.startedAt) / 86_400
        return max(1, Int(days / MoonPhase.synodicMonth) + 1)
    }

    // MARK: - The month, drawn
    //
    // Every night of this lunation as its own moon, new through full and back
    // to new. Tonight is ringed. It is the fastest way to see where you are
    // without reading a single word.

    private var monthStrip: some View {
        VStack(alignment: .leading, spacing: 12) {

            Eyebrow(text: "This month", trailing: "night \(moon.cycleDay)")

            let rows = strippedRows
            VStack(spacing: 14) {
                ForEach(rows.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        ForEach(rows[index], id: \.self) { night in
                            nightMoon(night)
                        }
                    }
                }
            }

            HStack(spacing: 14) {
                legend("New", 0.0)
                legend("First quarter", 0.25)
                legend("Full", 0.5)
                legend("Last quarter", 0.75)
            }
            .padding(.top, 2)
        }
    }

    /// The nights of this lunation, in rows that fit a phone.
    private var strippedRows: [[Int]] {
        let total = moon.cycleDays
        let all = Array(1...max(1, total))
        return stride(from: 0, to: all.count, by: 10).map {
            Array(all[$0 ..< min($0 + 10, all.count)])
        }
    }

    private func nightMoon(_ night: Int) -> some View {
        let fraction = Double(night - 1) / Double(max(1, moon.cycleDays))
        let isTonight = night == moon.cycleDay

        return VStack(spacing: 5) {
            MoonDisc(fraction: fraction, size: 20, glowing: false)
                .overlay(
                    Circle()
                        .strokeBorder(isTonight ? skin.evidence : Color.clear, lineWidth: 1.5)
                        .padding(-3)
                )

            Text("\(night)")
                .font(Ink.mono(8, weight: isTonight ? .bold : .regular))
                .foregroundStyle(isTonight ? skin.evidence : skin.ghost)
        }
        .frame(maxWidth: .infinity)
        .opacity(night < moon.cycleDay ? 0.45 : 1)
    }

    private func legend(_ label: String, _ fraction: Double) -> some View {
        HStack(spacing: 5) {
            MoonDisc(fraction: fraction, size: 11, glowing: false)
            Text(label.uppercased())
                .font(Ink.mono(8, weight: .medium))
                .kerning(0.6)
                .foregroundStyle(skin.dim)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Tonight

    private var tonight: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(guidance.personal ? "TONIGHT · YOURS" : "TONIGHT")
                    .font(Ink.tiny)
                    .kerning(1.8)
                    .foregroundStyle(guidance.personal ? skin.evidence : skin.dim)

                Spacer(minLength: 8)

                StrengthBar(strength: guidance.strength)
            }

            Text(guidance.headline)
                .font(Ink.title(20))
                .foregroundStyle(skin.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            Text(strengthWord(guidance.strength))
                .font(Ink.tiny)
                .kerning(1.4)
                .foregroundStyle(skin.dim)
                .padding(.top, 8)

            Text(guidance.body)
                .font(Ink.body(14))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            Rectangle().fill(skin.hairline).frame(height: 1).padding(.vertical, 16)

            Text("NOT TONIGHT")
                .font(Ink.tiny)
                .kerning(1.8)
                .foregroundStyle(skin.dim)

            Text(guidance.against)
                .font(Ink.body(14))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                .strokeBorder(
                    guidance.personal ? skin.evidence.opacity(0.5) : skin.hairline,
                    lineWidth: 1
                )
        )
    }

    private func strengthWord(_ strength: Int) -> String {
        switch strength {
        case 5: return "STRONGEST NIGHT OF THE CYCLE"
        case 4: return "A STRONG NIGHT"
        case 3: return "AN ORDINARY WORKING NIGHT"
        case 2: return "A QUIET NIGHT"
        default: return "A RESTING NIGHT"
        }
    }

    // MARK: - What you're waiting for

    @ViewBuilder
    private var nextBig: some View {
        if let next = LunarPlanner.nextBigOne(for: focus) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("NEXT NIGHT WORTH PLANNING AROUND")
                        .font(Ink.tiny)
                        .kerning(1.6)
                        .foregroundStyle(skin.dim)
                    Spacer(minLength: 6)
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(next.nightsAway)")
                        .font(Ink.display(38))
                        .foregroundStyle(skin.ink)
                        .monospacedDigit()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.nightsAway == 1 ? "night away" : "nights away")
                            .font(Ink.body(14, weight: .semibold))
                            .foregroundStyle(skin.dim)
                        Text("\(next.title) · \(next.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                            .font(Ink.body(14, weight: .bold))
                            .foregroundStyle(skin.ink)
                    }
                }

                Text(next.why)
                    .font(Ink.body(13))
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .overlay(
                RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                    .strokeBorder(skin.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: - The whole 29 days

    private var theMap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "The twenty-nine days", trailing: "you are here")

            Text("The same shape every month. Knowing which stretch you're in is most of the value — it stops you asking on a releasing night and releasing on an asking night.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(CycleStage.allCases) { stage in
                    StageRow(stage: stage, current: moon.stage == stage)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Dated, with meanings

    private var coming: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "What's coming", trailing: "next 6 months")

            Text("Tap any night to see what it's for. Ones marked in amber suit your line in particular.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            let nights = Array(LunarPlanner.keyNights(for: focus, months: 6).prefix(14))
            ForEach(nights) { night in
                KeyNightRow(
                    night: night,
                    open: expanded == night.id
                ) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        expanded = expanded == night.id ? nil : night.id
                    }
                }
            }
        }
    }

    // MARK: - Chapters behind you

    private var chapters: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Chapters", trailing: "\(store.totalReps) reps in all")

            Text("One chapter per lunation. Nothing here resets and nothing goes down — a line that takes twelve chapters isn't failing, it's twelve chapters of evidence.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            let all = store.recentChapters(4)
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

    // MARK: - Say what this is

    private var honesty: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ABOUT THE MOON")
                .font(Ink.tiny)
                .kerning(1.8)
                .foregroundStyle(skin.dim)

            Text("Every phase, percentage and date on this screen is computed from tonight's actual sky — no server, no guesswork, and it updates itself. Eclipse dates come from published tables.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            Text("What each night is *for* is the traditional framework, not physics, and this app won't pretend otherwise. What it reliably does is give the practice a rhythm — and a practice with a rhythm gets done.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
        )
    }
}

// MARK: - Pieces

private struct StrengthBar: View {
    let strength: Int
    @Environment(\.skin) private var skin

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { step in
                Capsule()
                    .fill(step <= strength ? skin.ink : skin.track)
                    .frame(width: 11, height: 3)
            }
        }
        .accessibilityLabel("Strength \(strength) of 5")
    }
}

private struct StageRow: View {
    let stage: CycleStage
    let current: Bool

    @Environment(\.skin) private var skin

    private var days: String {
        switch stage {
        case .plant:   return "DAY 0"
        case .build:   return "1–7"
        case .press:   return "8–13"
        case .read:    return "14"
        case .thank:   return "15–21"
        case .release: return "22–29"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(days)
                .font(Ink.mono(10, weight: .semibold))
                .foregroundStyle(current ? skin.ink : skin.dim)
                .frame(width: 46, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(stage.title)
                    .font(Ink.body(15, weight: current ? .bold : .semibold))
                    .foregroundStyle(current ? skin.ink : skin.dim)
                Text(stage.blurb)
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if current {
                Text("NOW")
                    .font(Ink.tiny)
                    .kerning(1.3)
                    .foregroundStyle(skin.ground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(skin.ink))
                    .padding(.top, 1)
            }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
        .opacity(current ? 1 : 0.75)
    }
}

private struct KeyNightRow: View {
    let night: KeyNight
    let open: Bool
    let toggle: () -> Void

    @Environment(\.skin) private var skin

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 11) {
                MoonDisc(
                    fraction: MoonPhase.moment(night.date).progress,
                    size: 22,
                    glowing: false
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(night.title)
                        .font(Ink.body(15, weight: .bold))
                        .foregroundStyle(skin.ink)
                    Text(night.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(night.whenLabel)
                        .font(Ink.tiny)
                        .kerning(1.2)
                        .foregroundStyle(night.personal ? skin.evidence : skin.dim)
                    StrengthBar(strength: night.strength)
                }
            }

            if open {
                Text(night.why)
                    .font(Ink.body(13))
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(
                    night.personal ? skin.evidence.opacity(0.45) : skin.hairline,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: toggle)
    }
}

// MARK: - Proof

struct ProofScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    @State private var composing = false
    @State private var reading = false
    @State private var editing: EvidenceEntry?
    @State private var editingSession: ScriptEntry?

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

                Text("On the days you don't believe any of it, this is the pile you read. Small counts — the pile is the point, not the size of any one thing in it.")
                    .font(Ink.body(15))
                    .foregroundStyle(skin.dim)
                    .padding(.top, 12)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Read this chapter back") { reading = true }
                    .buttonStyle(.outline)
                    .padding(.top, 20)

                if store.evidence.isEmpty {
                    Text(Library.noEvidence)
                        .font(Ink.body(15))
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 26)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.evidence) { entry in
                            Button { editing = entry } label: {
                                ProofRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 20)

                    Text("Tap any of them to change the wording or take it out.")
                        .font(Ink.tiny)
                        .foregroundStyle(skin.ghost)
                        .padding(.top, 10)
                }

                sessions

                Button("Something showed up") { composing = true }
                    .buttonStyle(.ink)
                    .padding(.top, 26)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $composing) { ProofComposer() }
        .sheet(item: $editing) { entry in ProofComposer(existing: entry) }
        .sheet(item: $editingSession) { entry in SessionEditor(entry: entry) }
        .sheet(isPresented: $reading) { ChapterReading() }
    }

    // MARK: - Sessions
    //
    // Where a finished visualisation goes. It used to go nowhere you could
    // find, which made the See screen feel like it threw your work away.

    @ViewBuilder
    private var sessions: some View {
        if !store.scripts.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: "Sessions", trailing: "\(store.scripts.count)")
                    .padding(.top, Space.section)

                Text("Every visualisation you've finished, how long you held it, and whatever you wrote afterwards.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    ForEach(store.scripts.prefix(20)) { entry in
                        Button { editingSession = entry } label: {
                            SessionRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

private struct SessionRow: View {
    let entry: ScriptEntry
    @Environment(\.skin) private var skin

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(entry.title) · \(entry.createdAt.relativeDayLabel)".uppercased())
                .font(Ink.tiny)
                .kerning(1.4)
                .foregroundStyle(skin.evidence)

            Text(entry.body.isEmpty ? "Held it, wrote nothing. That still counts." : entry.body)
                .font(Ink.body(15))
                .foregroundStyle(entry.body.isEmpty ? skin.dim : skin.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
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
