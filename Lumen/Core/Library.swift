//
//  Library.swift
//  Lumen
//
//  Written content. Kept in one place so the voice of the app stays consistent
//  and so it is easy to rewrite in your own words later.
//

import Foundation

enum Library {

    // MARK: - The daily line
    //
    // One is chosen per day, deterministically, so it doesn't change if you
    // reopen the app. It changes at midnight and not before.

    static let dailyLines: [String] = [
        "What you rehearse in private, you meet in public.",
        "Nothing is coming. It is already on its way back to you.",
        "The thought arrived for a reason. Thoughts don't visit strangers.",
        "You are not asking. You are remembering.",
        "Certainty is the whole technique. The rest is admin.",
        "Write it down and it stops being a wish.",
        "Say it until your body believes it. The body is the slow one.",
        "You have done this before. Look at your evidence.",
        "The universe does not negotiate. It delivers.",
        "Doubt is a habit, not a fact.",
        "Speak in the past tense. It works faster that way.",
        "You are allowed to want the whole thing.",
        "Ask once. Then act like the answer was yes.",
        "Gratitude is the receipt you write before the delivery.",
        "Whatever you keep returning to is returning to you.",
        "You cannot want something that isn't already reaching for you.",
        "Stop checking whether it worked. Checking is doubt in a nice coat.",
        "Your job is the feeling. The how is not your department.",
        "Everything you have now was once something you only imagined.",
        "Hold it lightly. Grip is the opposite of trust.",
        "The good is not rationed. Take the whole share.",
        "Talk about it like it has already happened, because it has.",
        "The delay is not a denial.",
        "Notice what showed up today. That was not an accident.",
        "You are a magnet with a memory.",
        "Decide, and let the world catch up.",
        "The version of you who has it already exists. Go and be them.",
        "Nothing good has ever required you to beg for it.",
        "Repetition is how belief gets installed.",
        "Trust is a muscle. This is the gym.",
        "You get what you rehearse, not what you wish for.",
        "Act as if, until there is no 'as if' left."
    ]

    static func dailyLine(for date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        guard !dailyLines.isEmpty else { return "" }
        return dailyLines[abs(day) % dailyLines.count]
    }

    // MARK: - Greeting

    static func greeting(name: String, date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let base: String
        switch hour {
        case 0..<5:   base = "Still awake"
        case 5..<12:  base = "Good morning"
        case 12..<18: base = "Good afternoon"
        default:      base = "Good evening"
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? base : "\(base), \(trimmed)"
    }

    // MARK: - After a ritual

    static let sealLines: [String] = [
        "Sealed. Now let it go.",
        "Written. It is out of your hands and into better ones.",
        "Done. Stop holding the seed up to the light.",
        "Sent. Go and live like it's handled.",
        "Logged. Now watch for the evidence.",
        "That's yours now. Walk away from it.",
        "Filed with the universe. No follow-up required."
    ]

    static func sealLine() -> String {
        sealLines.randomElement() ?? "Sealed."
    }

    // MARK: - Scripting prompts

    static let scriptPrompts: [String] = [
        "It's the evening of the day it happened. Walk me through it from waking up.",
        "Who is the first person you told, and what were the exact words?",
        "What does your morning look like now that this is normal?",
        "Describe the room you're standing in when you find out.",
        "What did you stop worrying about, and when did you notice you'd stopped?",
        "Write the thank-you note. It already happened.",
        "What's different about how you walk into a room now?",
        "Somebody asks how you did it. What do you tell them?"
    ]

    // MARK: - The Picture
    //
    // Visualisation. Eight sensory prompts, answered in your head, in order.
    // Never on a timer — you move when you're ready.

    static let picturePrompts: [String] = [
        "Where are you standing?",
        "What is the light like?",
        "What can you hear from where you are?",
        "What are you wearing?",
        "Who else is there?",
        "What did you just put down?",
        "What can you smell?",
        "What is the first thing you say out loud?"
    ]

    /// Shown once the eight are done.
    static let pictureClose = "Hold it for a moment longer, then let it go."

    static let pictureAsk = "What did you see?"

    static let pictureIntro = "Eight questions. Answer them in your head, in as much detail as you can stand. There is no timer — take as long as you like on each one."

    // MARK: - Starter affirmations, by area

    static func starters(for area: LifeArea) -> [String] {
        switch area {
        case .wealth:
            return [
                "Money finds me easily and often",
                "I always have more than I need",
                "I am paid generously for work I would do anyway",
                "Unexpected money arrives for me"
            ]
        case .love:
            return [
                "I am deeply loved exactly as I am",
                "Love is easy for me",
                "The right people keep finding me",
                "I am chosen, openly and without doubt"
            ]
        case .health:
            return [
                "My body is strong, rested and well",
                "I wake up with energy",
                "I am kind to my body and it answers back",
                "Healing is happening in me right now"
            ]
        case .work:
            return [
                "My work is seen and generously rewarded",
                "The right opportunities come to me first",
                "I am excellent at what I do and people know it",
                "Doors open for me before I knock"
            ]
        case .home:
            return [
                "I live in a home that feels like peace",
                "My home is full, warm and mine",
                "I am safe and settled",
                "Everything I need is already under this roof"
            ]
        case .spirit:
            return [
                "I am guided, and I trust what I am given",
                "I am always exactly where I'm meant to be",
                "The signs are clear and I can read them",
                "I trust the timing of my life"
            ]
        case .adventure:
            return [
                "The world opens itself to me",
                "I go wherever I want to go",
                "My life is full of first times",
                "Beautiful places are waiting for me"
            ]
        case .freedom:
            return [
                "My time belongs to me",
                "I answer to no one",
                "I choose how my days are spent",
                "I am free, and it is ordinary now"
            ]
        }
    }

    // MARK: - Writing guidance

    struct Rule: Identifiable {
        let title: String
        let detail: String
        var id: String { title }
    }

    static let rules: [Rule] = [
        Rule(title: "Present tense, always",
             detail: "Not \"I will have\" — \"I have\". The future tense keeps it in the future, permanently."),
        Rule(title: "Say it like it's already here",
             detail: "\"I am\" and \"I have\" beat \"I want\" and \"I need\". Wanting is a statement about not having."),
        Rule(title: "Keep it short enough to say in one breath",
             detail: "You're going to write this hundreds of times. Every extra word is friction."),
        Rule(title: "Name the feeling, not the mechanism",
             detail: "How it feels is your job. How it arrives is not. Leave the route to the universe."),
        Rule(title: "No negatives",
             detail: "\"I am debt free\" still says debt. Try \"I have more than enough\" instead."),
        Rule(title: "Make it yours",
             detail: "If it sounds like a poster, rewrite it. It should sound like you on a good day.")
    ]

    // MARK: - Empty states

    static let noIntentions = "Nothing written down yet. A thought stays a thought until it has ink on it."
    static let noEvidence = "No evidence logged. Start noticing — it's already happening, you're just not writing it down."
    static let noScripts = "Nothing scripted yet. Write from a day that hasn't happened, in the past tense."
    static let noReceived = "Nothing archived yet. This fills up. Give it time."
}
