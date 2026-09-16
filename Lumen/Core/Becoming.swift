//
//  Becoming.swift
//  Lumen
//
//  Becoming the person, rather than doing an impression of them.
//
//  The distinction this whole feature turns on:
//
//      Impersonating is borrowing the surface. The walk, the suit, the
//      one-liner. It is performance, it needs an audience, and it collapses
//      the second you are tired or embarrassed or on your own.
//
//      Becoming is the opposite direction of travel. You do not take on the
//      identity and then act it out. You do the acts, repeatedly, in small
//      unglamorous places, and the identity is what is left behind. You
//      become the person by accumulating the evidence that you already are.
//
//  That is not mysticism, it is how self-belief is actually built: you
//  believe what you have watched yourself do. Which is exactly why this
//  belongs in a manifestation app — the line you write is the claim, and
//  this is the part where you go and make the claim true.
//
//  Nothing here invents anything about you. You choose who you are becoming,
//  the app turns that into things a person like that would actually do
//  today, and then it keeps count of how many times you did them.
//

import Foundation

// MARK: - A quality, and what it actually costs

/// One trait of the person you're becoming.
///
/// Every trait carries three things: the impression of it (what people fake),
/// the real version (what it costs), and the acts — small, specific, doable
/// before bed, which is the only kind that ever works.
struct Trait: Identifiable, Hashable {

    let id: String
    let title: String
    /// The costume version. Named out loud so you can catch yourself wearing it.
    let impression: String
    /// What the trait actually is, underneath the costume.
    let truth: String
    /// The behaviours that leave the trait behind as residue.
    let acts: [Act]
    /// The tell — the one small thing that gives away who has it and who is acting.
    let tell: String

    var symbol: String { Trait.symbols[id] ?? "circle" }

    private static let symbols: [String: String] = [
        "composed": "wind",
        "certain": "target",
        "generous": "hands.sparkles",
        "disciplined": "metronome",
        "direct": "arrow.right",
        "unhurried": "tortoise",
        "warm": "flame",
        "capable": "wrench.and.screwdriver",
        "brave": "figure.stand",
        "honest": "eye",
        "present": "dot.circle",
        "unbothered": "moon"
    ]
}

/// One concrete behaviour. Small enough to do today; specific enough that you
/// can't argue about whether you did it.
struct Act: Identifiable, Hashable {
    let id: String
    let text: String
    /// What it costs — because an act with no cost casts no vote.
    let cost: String
}

// MARK: - The library

enum TraitLibrary {

    static let all: [Trait] = [

        Trait(
            id: "composed",
            title: "Composed",
            impression: "Being cold. Saying little and calling it mystery, when it's actually just fear of saying the wrong thing.",
            truth: "Composure is not the absence of the feeling. It's the gap you put between the feeling and what you do about it. Composed people feel everything — they just answer late.",
            acts: [
                Act(id: "composed-1", text: "When something lands badly today, count to four before you respond.", cost: "Four seconds of looking like you have nothing to say."),
                Act(id: "composed-2", text: "Leave one message unanswered until this evening, on purpose.", cost: "The itch of an unread badge."),
                Act(id: "composed-3", text: "Say \u{201C}let me think about that\u{201D} once, out loud, to a real person.", cost: "Admitting you don't already know."),
                Act(id: "composed-4", text: "Lower your voice one notch in the moment you'd normally raise it.", cost: "Losing the argument you were about to win loudly."),
                Act(id: "composed-5", text: "Do one thing slowly that you normally rush \u{2014} getting dressed, walking to the car.", cost: "Two minutes.")
            ],
            tell: "Watch their hands when they're waiting. Composed people are still. Impersonators fidget and compensate with the face."
        ),

        Trait(
            id: "certain",
            title: "Certain",
            impression: "Never admitting a mistake. Volume standing in for conviction.",
            truth: "Certainty is not being sure you're right. It's being sure you'll survive being wrong. That's why genuinely certain people change their mind so easily \u{2014} it costs them nothing.",
            acts: [
                Act(id: "certain-1", text: "Make one decision today in under a minute and don't revisit it.", cost: "The comfort of keeping the option open."),
                Act(id: "certain-2", text: "Say what you actually want, once, without softening it into a question.", cost: "Being told no, plainly."),
                Act(id: "certain-3", text: "Admit you were wrong about something small, without a single excuse attached.", cost: "Two seconds of feeling stupid."),
                Act(id: "certain-4", text: "Delete one thing from today that you only agreed to out of politeness.", cost: "Someone being mildly disappointed in you."),
                Act(id: "certain-5", text: "Write your line once without checking whether you believe it yet.", cost: "Nothing. That's the point.")
            ],
            tell: "Certain people ask more questions, not fewer. The impression asks none."
        ),

        Trait(
            id: "disciplined",
            title: "Disciplined",
            impression: "Talking about routines. Buying the equipment. The 5am post.",
            truth: "Discipline is doing the boring version on the day it means nothing. Everyone can do the dramatic version once. Nobody watches the Tuesday.",
            acts: [
                Act(id: "disc-1", text: "Do the smallest version of the thing you're avoiding \u{2014} five minutes, badly.", cost: "Not getting to say you did it properly."),
                Act(id: "disc-2", text: "Finish one thing you started that nobody is asking about.", cost: "An hour nobody will thank you for."),
                Act(id: "disc-3", text: "Put your phone in another room for the first twenty minutes of a task.", cost: "Twenty minutes of not being reachable."),
                Act(id: "disc-4", text: "Make the bed, or its equivalent \u{2014} the pointless tidy thing you skip.", cost: "Ninety seconds."),
                Act(id: "disc-5", text: "Go to bed at the time you said, once, with something unfinished.", cost: "Leaving a thread hanging overnight.")
            ],
            tell: "Disciplined people are quite boring about it. The performance is loud because the performance is all there is."
        ),

        Trait(
            id: "direct",
            title: "Direct",
            impression: "Being blunt and calling it honesty. Rudeness with a good excuse.",
            truth: "Direct is short, warm and unambiguous. It's the opposite of rude \u{2014} rudeness makes the other person do the work of decoding you.",
            acts: [
                Act(id: "direct-1", text: "Send one message with the ask in the first sentence.", cost: "No cushion to hide behind."),
                Act(id: "direct-2", text: "Say no to one thing today, without inventing a reason.", cost: "A slightly awkward pause."),
                Act(id: "direct-3", text: "Tell someone what you liked about what they did, specifically.", cost: "Being sincere on purpose, which is harder than it sounds."),
                Act(id: "direct-4", text: "Ask for the thing you've been hinting at.", cost: "Finding out the answer."),
                Act(id: "direct-5", text: "Cut the apology off the front of one sentence.", cost: "Sounding like you think you're allowed to speak.")
            ],
            tell: "Direct people leave you knowing exactly what happens next. You never leave a conversation with them wondering."
        ),

        Trait(
            id: "generous",
            title: "Generous",
            impression: "Giving where it's seen. Generosity with a receipt attached.",
            truth: "Generosity is giving away the thing you're short of \u{2014} time when you're busy, credit when you need it, attention when you're tired. Anything else is just having spare.",
            acts: [
                Act(id: "gen-1", text: "Give someone credit in front of a third person.", cost: "The credit."),
                Act(id: "gen-2", text: "Do one useful thing for someone who will never know it was you.", cost: "Being seen doing it."),
                Act(id: "gen-3", text: "Let someone finish a story you've already heard.", cost: "Four minutes and your impatience."),
                Act(id: "gen-4", text: "Pay for something small without making a thing of it.", cost: "A tenner and the thank-you."),
                Act(id: "gen-5", text: "Introduce two people who should know each other.", cost: "Losing your position in the middle.")
            ],
            tell: "Generous people are hard to thank. They change the subject."
        ),

        Trait(
            id: "unhurried",
            title: "Unhurried",
            impression: "Being late and calling it being relaxed.",
            truth: "Unhurried people are early. That's the whole trick \u{2014} they've bought themselves the time to be slow in. Rushing is a debt you took out earlier in the day.",
            acts: [
                Act(id: "unh-1", text: "Leave for one thing ten minutes earlier than you need to.", cost: "Ten minutes of waiting."),
                Act(id: "unh-2", text: "Eat one meal today without a screen.", cost: "Being alone with your own head for twenty minutes."),
                Act(id: "unh-3", text: "Walk somewhere you'd normally drive, or take the long way.", cost: "Time, which is the point."),
                Act(id: "unh-4", text: "Finish one conversation without checking your phone once.", cost: "Not knowing for ten minutes."),
                Act(id: "unh-5", text: "Sit still for three minutes before you start the day's first task.", cost: "Three minutes of feeling like you're wasting time.")
            ],
            tell: "Unhurried people don't talk about how busy they are. It doesn't occur to them as a topic."
        ),

        Trait(
            id: "brave",
            title: "Brave",
            impression: "Recklessness. Doing dangerous things where there's no real risk to you.",
            truth: "Bravery is almost never physical. It's saying the unpopular true thing in a room, asking for the money, going first. It's measured in social risk, and it's the rarest one on this list.",
            acts: [
                Act(id: "brave-1", text: "Say the thing everyone is thinking, in the room, once.", cost: "Being the one who said it."),
                Act(id: "brave-2", text: "Ask for more than you think you'll get.", cost: "Hearing no, in person."),
                Act(id: "brave-3", text: "Go first \u{2014} speak first, offer first, apologise first.", cost: "Not knowing how it lands until after."),
                Act(id: "brave-4", text: "Do one thing today you'd be embarrassed to be seen starting.", cost: "Being seen starting it."),
                Act(id: "brave-5", text: "Tell one person what you're actually trying to build.", cost: "It becoming real enough to fail at publicly.")
            ],
            tell: "Brave people look nervous. Courage without nerves is just not understanding the stakes."
        ),

        Trait(
            id: "capable",
            title: "Capable",
            impression: "Sounding like you know. Vocabulary doing the work of competence.",
            truth: "Capable is narrow and deep. It's being genuinely good at three things and openly hopeless at the rest \u{2014} which is why capable people are so relaxed about saying \u{201C}I don't know how to do that.\u{201D}",
            acts: [
                Act(id: "cap-1", text: "Learn one small mechanical thing properly today \u{2014} a shortcut, a knot, a setting.", cost: "Twenty minutes of being bad at it."),
                Act(id: "cap-2", text: "Say \u{201C}I don't know\u{201D} once without apologising for it.", cost: "The bluff."),
                Act(id: "cap-3", text: "Fix something small that's been annoying you for weeks.", cost: "Half an hour."),
                Act(id: "cap-4", text: "Do the part of your work you're worst at, first.", cost: "Starting the day losing."),
                Act(id: "cap-5", text: "Ask someone better than you how they do it.", cost: "Admitting they're better.")
            ],
            tell: "Capable people give you the caveat first. Impersonators give you the conclusion first."
        ),

        Trait(
            id: "warm",
            title: "Warm",
            impression: "Being nice. Agreeing with everything so that nobody leaves unhappy.",
            truth: "Warmth is attention, not agreement. It's remembering the detail, using the name, noticing that someone's off. Nice is about you. Warm is about them.",
            acts: [
                Act(id: "warm-1", text: "Use someone's name in the first sentence you say to them.", cost: "Nothing, and it's why nobody does it."),
                Act(id: "warm-2", text: "Follow up on something someone told you last week.", cost: "Having actually listened."),
                Act(id: "warm-3", text: "Ask a second question instead of telling your version of the story.", cost: "Your turn."),
                Act(id: "warm-4", text: "Message one person for no reason at all.", cost: "Looking like you need something. You don't."),
                Act(id: "warm-5", text: "Notice out loud when someone seems off.", cost: "Possibly being wrong.")
            ],
            tell: "Warm people ask about the thing you mentioned in passing. Nice people compliment your shoes."
        ),

        Trait(
            id: "honest",
            title: "Honest",
            impression: "Brutal truths, delivered to other people. Never about yourself.",
            truth: "Honesty starts inward and it's uncomfortable there first. If your honesty only ever costs other people something, it isn't honesty, it's a weapon with good branding.",
            acts: [
                Act(id: "hon-1", text: "Write down the real reason you haven't started the thing.", cost: "Reading it back."),
                Act(id: "hon-2", text: "Correct one small exaggeration you've been telling people.", cost: "Being slightly less impressive."),
                Act(id: "hon-3", text: "Tell someone the actual number \u{2014} what you earn, what you weigh, how far along it is.", cost: "The version you preferred."),
                Act(id: "hon-4", text: "Say \u{201C}I forgot\u{201D} instead of an excuse.", cost: "Looking careless once."),
                Act(id: "hon-5", text: "Log the evidence you didn't like as well as the evidence you did.", cost: "A less flattering month.")
            ],
            tell: "Honest people are unremarkable in an argument and devastating on paper."
        ),

        Trait(
            id: "present",
            title: "Present",
            impression: "Talking about presence. Mentioning that you meditate.",
            truth: "Present is a door you walk through a hundred times a day and mostly don't. It's not a state you achieve, it's the act of coming back \u{2014} which means the person who's distracted constantly and returns constantly is winning.",
            acts: [
                Act(id: "pres-1", text: "Put the phone face down and out of reach for one conversation.", cost: "The reflex."),
                Act(id: "pres-2", text: "Notice three things in the room you hadn't noticed.", cost: "Ten seconds."),
                Act(id: "pres-3", text: "Do one task without a second tab, podcast or screen running.", cost: "Boredom, which is the withdrawal symptom."),
                Act(id: "pres-4", text: "Finish one thing before opening the next.", cost: "The dopamine of switching."),
                Act(id: "pres-5", text: "When you catch yourself gone, come back without telling yourself off.", cost: "The little self-attack you're used to.")
            ],
            tell: "Present people make you feel interesting. That's the whole effect, and it's not a technique."
        ),

        Trait(
            id: "unbothered",
            title: "Unbothered",
            impression: "Pretending not to care. Which is caring, loudly, in a costume.",
            truth: "Unbothered is having enough going on that other people's opinions are genuinely not load-bearing. It is a by-product of having work you respect, not a posture you adopt.",
            acts: [
                Act(id: "unb-1", text: "Post, send or say something without checking who's seen it.", cost: "Not knowing."),
                Act(id: "unb-2", text: "Let one wrong thing about you stand uncorrected.", cost: "Being slightly misunderstood."),
                Act(id: "unb-3", text: "Spend an hour on the thing you'd do even if nobody ever saw it.", cost: "An hour with no return."),
                Act(id: "unb-4", text: "Don't look at the numbers today \u{2014} any of them.", cost: "The check."),
                Act(id: "unb-5", text: "Wear, say or do the thing you like that you've been told is a bit much.", cost: "Being a bit much.")
            ],
            tell: "Unbothered people don't announce what they're not bothered about."
        )
    ]

    static func trait(_ id: String) -> Trait? { all.first { $0.id == id } }

    static func act(_ id: String) -> Act? {
        for trait in all {
            if let found = trait.acts.first(where: { $0.id == id }) { return found }
        }
        return nil
    }
}

// MARK: - The sheet

/// One vote, cast on one day.
struct Vote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var actID: String
    var traitID: String
    var date: Date = Date()
    /// Optional \u{2014} what happened when you did it.
    var note: String = ""
}

/// Who you're becoming, and the running tally of evidence that you already are.
struct CharacterSheet: Codable, Hashable {

    /// In your own words. "The version of me that runs the studio." Not a
    /// celebrity, though the app doesn't police it \u{2014} it's your sheet.
    var who: String = ""
    /// Up to three. More than three and it's a wish list, not a person.
    var traitIDs: [String] = []
    var votes: [Vote] = []
    var startedAt: Date = Date()
    /// Set once the user has read the short explanation, so it stops leading.
    var readTheIdea: Bool = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        who          = c.get(.who, "")
        traitIDs     = c.get(.traitIDs, [String]())
        votes        = c.get(.votes, [Vote]())
        startedAt    = c.get(.startedAt, Date())
        readTheIdea  = c.get(.readTheIdea, false)
    }

    var isSet: Bool { !traitIDs.isEmpty }

    var traits: [Trait] { traitIDs.compactMap { TraitLibrary.trait($0) } }

    func votes(on day: Date) -> [Vote] {
        votes.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    func didToday(_ actID: String) -> Bool {
        votes(on: Date()).contains { $0.actID == actID }
    }

    func votes(forTrait id: String) -> Int {
        votes.filter { $0.traitID == id }.count
    }

    /// Days on which at least one vote was cast. The honest denominator.
    var daysActed: Int {
        Set(votes.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var daysSinceStart: Int {
        max(1, Calendar.current.dateComponents([.day], from: startedAt, to: Date()).day.map { $0 + 1 } ?? 1)
    }

    /// Not a streak. Streaks punish one bad day and this is a long game.
    var showingUpRate: Double {
        min(1, Double(daysActed) / Double(daysSinceStart))
    }
}

// MARK: - Where you are in it

/// The honest stages of becoming somebody. Named so the user can locate
/// themselves, and so the horrible middle one has a name and stops being
/// evidence that it isn't working.
enum BecomingStage: Int, CaseIterable, Identifiable {
    case deciding, acting, cringing, forgetting, being

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .deciding:   return "Deciding"
        case .acting:     return "Acting"
        case .cringing:   return "The cringe"
        case .forgetting: return "Forgetting"
        case .being:      return "Being"
        }
    }

    var body: String {
        switch self {
        case .deciding:
            return "You've named it. Nothing has changed yet and it feels slightly ridiculous to have written it down. That's correct \u{2014} at this stage it is only a claim."
        case .acting:
            return "You're doing the acts and you're aware of doing them. It feels deliberate and a bit false, because it is deliberate. Everyone mistakes this stage for lying. It isn't; it's rehearsal, and there is no route that skips it."
        case .cringing:
            return "The worst part, and the one nearly everybody quits in. You catch yourself doing it and you feel like a fraud. The feeling is not a verdict on you \u{2014} it is the gap between the old self-image and the new evidence, and it only closes by adding more evidence."
        case .forgetting:
            return "You do one of the acts without having planned it, and only notice afterwards. That's the turn. From here it stops being effort and starts being preference."
        case .being:
            return "Somebody describes you with the word and it doesn't occur to you to argue. You are not performing it and you can't fully remember choosing it. That's the whole thing."
        }
    }

    var marker: String {
        switch self {
        case .deciding:   return "Day one"
        case .acting:     return "A few votes in"
        case .cringing:   return "Around the second week"
        case .forgetting: return "A chapter or two"
        case .being:      return "Eventually, and quietly"
        }
    }
}

extension CharacterSheet {
    var stage: BecomingStage {
        let count = votes.count
        switch count {
        case 0:        return .deciding
        case 1..<12:   return .acting
        case 12..<40:  return .cringing
        case 40..<120: return .forgetting
        default:       return .being
        }
    }
}

// MARK: - What you're doing today

extension CharacterSheet {

    /// One act per chosen trait, rotated by the day so it never becomes
    /// wallpaper, and stable within the day so ticking it doesn't reshuffle.
    func todaysActs(on day: Date = Date()) -> [(trait: Trait, act: Act)] {
        let index = Calendar.current.ordinality(of: .day, in: .era, for: day) ?? 0
        return traits.enumerated().compactMap { offset, trait in
            guard !trait.acts.isEmpty else { return nil }
            let pick = (index + offset * 3) % trait.acts.count
            return (trait, trait.acts[pick])
        }
    }

    /// Everything you've done today, whatever day it was offered on.
    func doneToday(on day: Date = Date()) -> Int { votes(on: day).count }
}

// MARK: - The moon and the man
//
// The lunar half of the app and this half are the same practice from two
// directions: the line is the claim, the acts are the proof. So the moon
// tells you which kind of act to lean on tonight rather than giving you a
// separate calendar to keep.

extension MoonPhaseName {

    /// What becoming looks like on this phase.
    var becomingNote: String {
        switch self {
        case .newMoon:
            return "Empty sky, so name it rather than prove it. Tonight is for deciding who you're becoming, not for doing anything impressive about it."
        case .waxingCrescent:
            return "First small acts. Do the least impressive version — the one nobody would be able to see you doing."
        case .firstQuarter:
            return "This is where it gets awkward and you notice yourself performing. Do the act anyway. The awkwardness is the rehearsal, not a verdict."
        case .waxingGibbous:
            return "Push on the one that costs the most. Whichever act you keep skipping is the one actually holding the identity in place."
        case .fullMoon:
            return "Read the votes back. Count the days you showed up, not the days you didn't. This is the night you're allowed to notice you've changed."
        case .waningGibbous:
            return "Do one in front of somebody. An act only becomes identity once it survives being witnessed."
        case .lastQuarter:
            return "Name one behaviour of the old version you're finished with. Not a trait — a behaviour, small and specific."
        case .waningCrescent:
            return "Do nothing on purpose. Becoming is not a grind and the dark days are where the new thing stops feeling like effort."
        }
    }
}
