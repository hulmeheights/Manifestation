//
//  BecomeScreen.swift
//  Lumen
//
//  The other half of the practice. Writing the line is the claim; this is
//  where you go and make it true, by doing small things a person like that
//  would do until you stop being able to tell the difference.
//

import SwiftUI

struct BecomeScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    @State private var choosing = false
    @State private var readingIdea = false
    @State private var openTrait: Trait?

    private var sheet: CharacterSheet { store.character }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                head

                if !sheet.isSet {
                    empty
                } else {
                    tonight.padding(.top, Space.section)
                    acts.padding(.top, 14)
                    theIdea.padding(.top, Space.section)
                    stages.padding(.top, Space.section)
                    tally.padding(.top, Space.section)
                    traitsList.padding(.top, Space.section)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $choosing) { CharacterEditor() }
        .sheet(isPresented: $readingIdea) { BecomingIdea() }
        .sheet(item: $openTrait) { trait in TraitDetail(trait: trait) }
    }

    // MARK: - Head

    private var head: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Become", trailing: sheet.isSet ? sheet.stage.title : nil)

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

            Text("Pick who you're becoming, and the app will turn it into things you can actually do today.")
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

    // MARK: - Tonight

    private var tonight: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                MoonDisc(fraction: store.moon.progress, size: 34, glowing: false)
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

    // MARK: - The acts

    private var acts: some View {
        VStack(alignment: .leading, spacing: 0) {

            Eyebrow(
                text: "Today",
                trailing: "\(sheet.doneToday()) cast"
            )
            .padding(.bottom, 4)

            ForEach(Array(sheet.todaysActs().enumerated()), id: \.offset) { _, pair in
                ActRow(trait: pair.trait, act: pair.act)
            }

            Text("Tick it after you've done it, not before. A vote you didn't earn is the only way to break this.")
                .font(Ink.tiny)
                .foregroundStyle(skin.ghost)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Impersonating vs becoming

    private var theIdea: some View {
        Button { readingIdea = true } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Impersonating and becoming")
                    .font(Ink.body(16, weight: .semibold))
                    .foregroundStyle(skin.ink)

                Text("Why the costume never holds, and what to do instead. Four minutes.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(card)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stages

    private var stages: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Where you are")
                .padding(.bottom, 10)

            ForEach(BecomingStage.allCases) { stage in
                StageLine(stage: stage, current: stage == sheet.stage)
            }
        }
    }

    // MARK: - Tally

    private var tally: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "The evidence")

            HStack(spacing: 8) {
                tile("\(sheet.votes.count)", "votes cast")
                tile("\(sheet.daysActed)", "days you showed up")
                tile("\(Int(sheet.showingUpRate * 100))%", "of days since you started")
            }

            Text("There is no streak here on purpose. A streak makes one bad day mean something, and one bad day doesn't mean anything. What you're building is a pile you can read back.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Ink.display(24))
                .foregroundStyle(skin.ink)
                .monospacedDigit()
            Text(label.uppercased())
                .font(Ink.tiny)
                .kerning(1.1)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(card)
    }

    // MARK: - Your traits

    private var traitsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "What you chose", trailing: "Change")
                .contentShape(Rectangle())
                .onTapGesture { choosing = true }
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

    private var done: Bool { store.character.didToday(act.id) }

    var body: some View {
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

                    Text("Costs you: \(act.cost)")
                        .font(Ink.small)
                        .foregroundStyle(skin.ghost)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(skin.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - A stage line

private struct StageLine: View {

    @Environment(\.skin) private var skin
    let stage: BecomingStage
    let current: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Circle()
                .fill(current ? skin.evidence : skin.hairline)
                .frame(width: 7, height: 7)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stage.title)
                        .font(Ink.body(15, weight: current ? .semibold : .regular))
                        .foregroundStyle(current ? skin.ink : skin.dim)
                    Spacer()
                    Text(stage.marker.uppercased())
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
}
