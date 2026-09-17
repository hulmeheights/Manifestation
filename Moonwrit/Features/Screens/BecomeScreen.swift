//
//  BecomeScreen.swift
//  Moonwrit
//
//  The other half of the practice. Writing the line is the claim; this is
//  where you go and make it true, by doing small things a person like that
//  would do until you stop being able to tell the difference.
//
//  Rebuilt so it answers the two questions it was leaving unanswered:
//  what do I do right now, and what happens next.
//

import SwiftUI
import Combine

struct BecomeScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    @State private var choosing = false
    @State private var readingIdea = false
    @State private var openTrait: Trait?
    @State private var swapping: Trait?
    @State private var writingOwn: Trait?
    @State private var now = Date()

    private let tick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var sheet: CharacterSheet { store.character }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                head

                if !sheet.isSet {
                    empty
                } else {
                    whereYouAre.padding(.top, 20)
                    acts.padding(.top, Space.section)
                    tonight.padding(.top, Space.section)
                    theIdea.padding(.top, 14)
                    stages.padding(.top, Space.section)
                    traitsList.padding(.top, Space.section)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .onReceive(tick) { now = $0 }
        .sheet(isPresented: $choosing) { CharacterEditor() }
        .sheet(isPresented: $readingIdea) { BecomingIdea() }
        .sheet(item: $openTrait) { trait in TraitDetail(trait: trait) }
        .sheet(item: $swapping) { trait in ActPicker(trait: trait) }
        .sheet(item: $writingOwn) { trait in OwnActEditor(trait: trait) }
    }

    // MARK: - Head

    private var head: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow(text: "Become")
                Spacer(minLength: 8)
                if sheet.isSet {
                    Button("Edit") { choosing = true }
                        .buttonStyle(.plain)
                        .font(Ink.label)
                        .foregroundStyle(skin.evidence)
                }
            }

            Text(sheet.who.isEmpty ? "Who you're\nbecoming." : sheet.who)
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    // MARK: - Nothing chosen yet

    private var empty: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("You don't become somebody by deciding to be them. You become them by doing the things they'd do, in small unimpressive places, until there's too much evidence to argue with.")
                .font(Ink.body(16))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            Text("Pick who you're becoming and the app turns it into three things you can do today. It'll do that again tomorrow, and the day after, for as long as you keep turning up.")
                .font(Ink.body(16))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            Button("Choose the character") { choosing = true }
                .buttonStyle(.ink)
                .frame(maxWidth: .infinity)

            Button("Read how this works first") { readingIdea = true }
                .buttonStyle(.outline)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, Space.section)
    }

    // MARK: - Where you are, said plainly

    private var whereYouAre: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(sheet.stage.title)
                    .font(Ink.title(19))
                    .foregroundStyle(skin.ink)
                Spacer(minLength: 8)
                Text("\(sheet.votes.count) \(sheet.votes.count == 1 ? "vote" : "votes")")
                    .font(Ink.mono(12, weight: .semibold))
                    .foregroundStyle(skin.dim)
            }

            Text(sheet.stage.body)
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            if let next = sheet.nextStage, let left = sheet.votesToNextStage {
                Meter(progress: sheet.progressToNextStage)

                Text("\(left) more \(left == 1 ? "act" : "acts") and you're into \(next.title.lowercased()). There's no clock on it — do them at whatever pace you actually do them.")
                    .font(Ink.small)
                    .foregroundStyle(skin.ghost)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("There's no stage after this one. Keep going anyway — it's not a game you finish.")
                    .font(Ink.small)
                    .foregroundStyle(skin.ghost)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    // MARK: - The acts

    private var acts: some View {
        VStack(alignment: .leading, spacing: 0) {

            Eyebrow(
                text: "Do these today",
                trailing: "\(sheet.doneToday()) of \(sheet.todaysActs().count)"
            )

            Text("One per trait you chose. They're yours until midnight, then a fresh set — next in \(sheet.timeToNextSet(from: now)). Tick one only after you've actually done it.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .fixedSize(horizontal: false, vertical: true)

            let pairs = sheet.todaysActs()
            ForEach(pairs.indices, id: \.self) { index in
                ActRow(
                    trait: pairs[index].trait,
                    act: pairs[index].act,
                    onSwap: { swapping = pairs[index].trait },
                    onWriteOwn: { writingOwn = pairs[index].trait }
                )
            }

            Text("Doesn't fit your day? Swap it for another, or write your own — an act only works if it's something you could genuinely do before bed.")
                .font(Ink.tiny)
                .foregroundStyle(skin.ghost)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Tonight's moon

    private var tonight: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                MoonDisc(fraction: store.moon.progress, size: 30, glowing: false)
                Text(store.moon.phase.title)
                    .font(Ink.body(14, weight: .semibold))
                    .foregroundStyle(skin.ink)
                Spacer()
            }

            Text(store.moon.phase.becomingNote)
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    // MARK: - Impersonating vs becoming

    private var theIdea: some View {
        Button { readingIdea = true } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Impersonating and becoming")
                        .font(Ink.body(16, weight: .semibold))
                        .foregroundStyle(skin.ink)

                    Text("Why the costume never holds, and what to do instead. Four minutes.")
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(skin.dim)
            }
            .padding(16)
            .background(card)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stages

    private var stages: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "The whole road")

            Text("Five stages, and the only thing that moves you along is acts done. Nothing here expires and nothing is lost by taking a week off.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(BecomingStage.allCases) { stage in
                StageLine(
                    stage: stage,
                    current: stage == sheet.stage,
                    reached: sheet.votes.count >= CharacterSheet.threshold(stage)
                )
            }
        }
    }

    // MARK: - Your traits

    private var traitsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "What you chose", trailing: "\(sheet.votes.count) cast in all")
                .padding(.bottom, 10)

            ForEach(sheet.traits) { trait in
                Button { openTrait = trait } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: trait.symbol)
                            .font(.system(size: 15))
                            .foregroundStyle(skin.dim)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(trait.title)
                                .font(Ink.body(16, weight: .semibold))
                                .foregroundStyle(skin.ink)
                            Text(trait.truth)
                                .font(Ink.small)
                                .foregroundStyle(skin.dim)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)

                        Text("\(sheet.votes(forTrait: trait.id))")
                            .font(Ink.mono(13))
                            .foregroundStyle(skin.ghost)
                    }
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(skin.hairline).frame(height: 1)
                    }
                }
                .buttonStyle(.plain)
            }

            Button("Change who you're becoming") { choosing = true }
                .buttonStyle(.outline)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
        }
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
            .fill(skin.card)
            .overlay(
                RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                    .strokeBorder(skin.hairline, lineWidth: 1)
            )
    }
}

// MARK: - One act

private struct ActRow: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    let trait: Trait
    let act: Act
    let onSwap: () -> Void
    let onWriteOwn: () -> Void

    private var done: Bool { store.character.didToday(act.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Button {
                if done {
                    store.withdrawVote(actID: act.id)
                } else {
                    store.castVote(act: act, trait: trait)
                    Haptics.seal(store.profile.hapticsEnabled)
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {

                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(done ? skin.evidence : skin.hairline)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(trait.title.uppercased())
                            .font(Ink.tiny)
                            .kerning(1.4)
                            .foregroundStyle(skin.dim)

                        Text(act.text)
                            .font(Ink.body(16))
                            .foregroundStyle(done ? skin.dim : skin.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if !act.cost.isEmpty {
                            Text("Costs you: \(act.cost)")
                                .font(Ink.small)
                                .foregroundStyle(skin.ghost)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !done {
                HStack(spacing: 16) {
                    Button("Swap this one", action: onSwap)
                    Button("Write my own", action: onWriteOwn)
                    Spacer()
                }
                .buttonStyle(.plain)
                .font(Ink.small)
                .foregroundStyle(skin.evidence)
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }
}

// MARK: - A stage line

private struct StageLine: View {

    @Environment(\.skin) private var skin
    let stage: BecomingStage
    let current: Bool
    let reached: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Circle()
                .fill(current ? skin.evidence : (reached ? skin.dim : skin.hairline))
                .frame(width: 7, height: 7)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stage.title)
                        .font(Ink.body(15, weight: current ? .semibold : .regular))
                        .foregroundStyle(current ? skin.ink : skin.dim)
                    Spacer()
                    Text(thresholdLabel.uppercased())
                        .font(Ink.tiny)
                        .kerning(1.1)
                        .foregroundStyle(skin.ghost)
                }

                if current {
                    Text(stage.body)
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }

    private var thresholdLabel: String {
        let n = CharacterSheet.threshold(stage)
        return n == 0 ? "Start" : "\(n) acts"
    }
}
