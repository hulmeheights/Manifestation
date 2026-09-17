//
//  BecomingIdea.swift
//  Moonwrit
//
//  The explanation. The user asked the app to teach this properly, so it is
//  written out rather than reduced to a tooltip: what the difference between
//  impersonating and becoming actually is, and what you do about it.
//

import SwiftUI

struct BecomingIdea: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    var body: some View {
        NavigationStack {
            ZStack {
                NightGround()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        MoonDisc(fraction: store.moon.progress, size: 76)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)

                        Text("You can be\nJames Bond.")
                            .font(Ink.hero)
                            .foregroundStyle(skin.ink)
                            .padding(.top, 28)

                        Text("You just can't do it by putting on the suit.")
                            .font(Ink.line)
                            .foregroundStyle(skin.dim)
                            .padding(.top, 12)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section.title.uppercased())
                                    .font(Ink.tiny)
                                    .kerning(1.6)
                                    .foregroundStyle(skin.evidence)

                                ForEach(section.paragraphs, id: \.self) { para in
                                    Text(para)
                                        .font(Ink.body(16))
                                        .foregroundStyle(skin.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, Space.section)
                        }

                        Text("None of this asks you to believe anything. It asks you to do small things and then look at what you did.")
                            .font(Ink.title(19))
                            .foregroundStyle(skin.ink)
                            .padding(.top, Space.section)
                            .fixedSize(horizontal: false, vertical: true)

                        Button("Choose the character") {
                            var sheet = store.character
                            sheet.readTheIdea = true
                            store.character = sheet
                            dismiss()
                        }
                        .buttonStyle(.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, 44)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("How this works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(skin.ink)
                }
            }
        }
        .skin(store.skin)
    }

    struct Passage: Identifiable {
        let id = UUID()
        let title: String
        let paragraphs: [String]
    }

    private var sections: [Passage] {
        [
            Passage(title: "The mistake everybody makes", paragraphs: [
                "Impersonating runs one way: you decide who you want to be, and then you try to look like it. The walk, the watch, the line you rehearsed in the car. It needs an audience, it's exhausting, and it drops the second you're tired or embarrassed or on your own in the kitchen at 11pm.",
                "It fails for a structural reason, not a moral one. You are copying the output. The person you're copying arrived at that output through years of decisions you didn't make, and the surface is the last thing to appear, not the first."
            ]),

            Passage(title: "Which way round it actually goes", paragraphs: [
                "Becoming runs the other way. You don't take the identity and act it out. You do the acts, in small unglamorous places, and the identity is the residue.",
                "This is not a spiritual claim. It's how self-belief is built in the first place: you believe what you have watched yourself do. Nobody talks themselves into thinking they're brave. They notice, after the fourth time, that they went first again.",
                "So the unit of work is not the character. It's the act. And an act is only worth casting if it costs you something, because the ones that cost nothing teach you nothing about who you are."
            ]),

            Passage(title: "Why Bond, specifically, is a bad target", paragraphs: [
                "Not because it's too ambitious — because it's a bundle. \u{201C}Bond\u{201D} is composure plus certainty plus capability plus not caring what the room thinks, and you cannot practise a bundle. You can only practise one strand at a time.",
                "Pull him apart and it becomes doable. Composure is answering four seconds late instead of straight away. Certainty is deciding in under a minute and not revisiting it. Capability is being genuinely good at three things and openly hopeless at the rest. Every one of those is something you could do before you go to bed tonight.",
                "That's what this section does: you name the person, the app pulls them apart into strands, and gives you today's version of one."
            ]),

            Passage(title: "The part nobody warns you about", paragraphs: [
                "There is a stretch in the middle where you feel like a fraud. You'll catch yourself doing the composed thing and think: I'm performing. This is fake.",
                "It is not fake and it is not a warning sign. It's the gap between the old self-image and the new evidence, and it is the single most common place people quit — usually while telling themselves they were being honest by stopping.",
                "The gap doesn't close by thinking about it. It closes by adding evidence to the pile until the old picture is outvoted. That's why this screen counts votes rather than days."
            ]),

            Passage(title: "How to tell which one you're doing", paragraphs: [
                "One test, and it's reliable. Would you still do this act if nobody ever found out?",
                "If yes, it's becoming. If the whole appeal is that somebody sees it, you're impersonating, and it will come off in the wash.",
                "Second test: does it cost you something today? Buying the coat doesn't. Saying the unpopular true thing in the meeting does."
            ]),

            Passage(title: "How this fits the rest of the app", paragraphs: [
                "The line you write is the claim. This is where you make the claim true.",
                "There's a reason the two sit in the same app. Writing an affirmation three, six and nine times is training the sentence. Doing the act is training the person. Do only the first and you get a very well-rehearsed sentence about somebody who doesn't exist yet.",
                "And it maps onto the moon the same way everything else here does: the new moon for naming it, the waxing week for doing the ones that cost, the full moon for reading back what you've already become, the dark days for leaving it alone."
            ])
        ]
    }
}
