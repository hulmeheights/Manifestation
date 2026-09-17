//
//  Library.swift
//  Moonwrit
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
    // Visualisation. The whole trick is that you are not imagining a thing you
    // WANT — you are remembering a moment you are already standing in. Every
    // prompt is written in the present, from inside it, so there is no way to
    // answer them from the outside looking in.

    static let pictureIntro = """
    You are not imagining something you want. You are standing in a moment that has already happened.

    Eight questions, answered in your head, from inside it. Present tense, as though you are there right now — because in the only place that matters, you are.

    There is no timer. Take as long as you like on each one.
    """

    static let pictureRule = "If you catch yourself saying \u{201C}I would\u{201D} or \u{201C}it will be\u{201D}, stop and start that answer again. It is happening now."

    /// The prompts, grouped by what they're asking you to notice.
    ///
    /// A session takes one from each group, so you always get the full sweep
    /// — place, light, sound, body, people, objects, smell, speech — but
    /// never the same eight questions twice in a row. Asking "what can you
    /// hear" four sessions running is how visualisation turns into a form to
    /// fill in, and the whole point is that it doesn't.
    static let picturePromptGroups: [[String]] = [
        [   // Place
            "You are standing in it. Where are you?",
            "Look down. What's under your feet?",
            "You've just walked in. What's the first thing you see?",
            "Turn around. What's behind you?"
        ],
        [   // Light
            "What is the light doing?",
            "What time of day is it, and how do you know?",
            "Where is the light coming from?",
            "Is it warm or cold where you're standing?"
        ],
        [   // Sound
            "What can you hear right now?",
            "What's the quietest thing you can hear?",
            "Is there music, or is it just the room?",
            "What sound tells you this is real?"
        ],
        [   // Body and clothes
            "What are you wearing?",
            "How are you standing?",
            "What's in your hands?",
            "What does your face do when nobody's watching you?"
        ],
        [   // People
            "Who else is here with you?",
            "Who is the first person you'd tell?",
            "Someone looks at you differently now. Who?",
            "Who isn't here, and are you alright about that?"
        ],
        [   // Objects and aftermath
            "What have you just put down?",
            "What's on the table?",
            "What did you get rid of to make room for this?",
            "What's the one object that proves it happened?"
        ],
        [   // Smell and air
            "What can you smell?",
            "What's the air like?",
            "What's cooking, or burning, or brewing?",
            "Is there a smell here you'd recognise anywhere?"
        ],
        [   // Speech and feeling
            "You say something out loud. What is it?",
            "Somebody says your name. How do they say it?",
            "What do you feel in your chest?",
            "What's the sentence you've been waiting to say?"
        ]
    ]

    /// Eight questions for one session: one from each group, in a shuffled
    /// order, different every time you sit down.
    static func pictureQuestions() -> [String] {
        picturePromptGroups.compactMap { $0.randomElement() }.shuffled()
    }

    /// Shown once the eight are done.
    static let pictureClose = "Stay in it a moment longer. Then let it go \u{2014} it\u{2019}s handled."

    static let pictureAsk = "What did you see?"

    static let pictureAskDetail = "Write it in the past tense, as though you\u{2019}ve just come back from it. \u{201C}I was standing\u{2026}\u{201D}, not \u{201C}I would be standing\u{2026}\u{201D}"

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

    // MARK: - The guide
    //
    // Nobody reads onboarding, so these live in one place you can come back to
    // and also surface where they're relevant.

    struct Card: Identifiable {
        let question: String
        let answer: String
        let detail: String
        var id: String { question }
    }

    static let guide: [Card] = [
        Card(
            question: "Is writing it enough on its own?",
            answer: "No, and the app would be lying if it said otherwise.",
            detail: "Writing the line trains the sentence. It does not train the person. That is what the Become tab is for \u{2014} you take the character you are claiming to be, pull them apart into things you could actually do today, and do one. The line is the claim; the acts are what make the claim true. Do only the first and you end up with a very well-rehearsed sentence about somebody who does not exist yet."
        ),
        Card(
            question: "What is the difference between impersonating and becoming?",
            answer: "Which end you start from.",
            detail: "Impersonating takes the surface \u{2014} the walk, the suit, the line \u{2014} and puts it on. It needs an audience and it comes off the moment you are tired. Becoming goes the other way: you do the small unglamorous acts, repeatedly, and the identity is what is left behind. The test is one question. Would you still do this if nobody ever found out? If yes, it is becoming. If the whole appeal is being seen doing it, it is a costume. Become \u{2192} Impersonating and becoming has the long version."
        ),
        Card(
            question: "Why present tense?",
            answer: "Because the future tense keeps it in the future.",
            detail: "\u{201C}I will have\u{201D} is a statement about not having it. \u{201C}I have\u{201D} puts it in the only place anything can actually happen, which is now. You are not lying to yourself \u{2014} you are deciding."
        ),
        Card(
            question: "Why type it out every time?",
            answer: "Because reading is too fast to count.",
            detail: "Typing is slow. It occupies your hands and your eyes, and it is very hard to do while thinking about something else. That difficulty is the point \u{2014} it is the part that installs. It will feel boring by the fourth rep. Boring is the target."
        ),
        Card(
            question: "Why three, six and nine?",
            answer: "Three when the day is soft, six when it\u{2019}s loudest, nine as the last thing you hand your sleeping mind.",
            detail: "The numbers matter less than the fact that there are three of them, spread across the day. Move the hours to fit your life \u{2014} the counts stay put."
        ),
        Card(
            question: "Why the moon?",
            answer: "Because a practice with no shape becomes a chore.",
            detail: "The moon gives you a beginning, a middle and a review \u{2014} twenty-nine days you didn\u{2019}t have to invent. It\u{2019}s also the one clock that isn\u{2019}t yours, which helps. And some nights carry far more weight than others; the app will tell you which."
        ),
        Card(
            question: "Why only one line at a time?",
            answer: "Eighteen reps on one line is a practice. Three each on six lines is a list.",
            detail: "Write down everything you want \u{2014} there\u{2019}s no limit. Then give the light to the one that changes the most, and let the rest wait. They aren\u{2019}t going anywhere, and nothing you\u{2019}ve written is ever lost."
        ),
        Card(
            question: "What is the See screen for?",
            answer: "Writing convinces the mind. Seeing makes it specific.",
            detail: "You are not imagining something you want. You are standing inside a moment that has already happened, and answering questions from in there \u{2014} present tense, first person. If you catch yourself saying \u{201C}it would be\u{201D}, start that answer again. Specific is what makes it feel already true."
        ),
        Card(
            question: "Why write down what shows up?",
            answer: "Because on the days you don\u{2019}t believe any of it, this is the pile you read.",
            detail: "It turns \u{201C}it\u{2019}s working\u{201D} from a feeling into a list you can count. Small counts \u{2014} the pile is the point, not the size of any one thing in it. Every other app skips this, and it\u{2019}s the one that does the work."
        ),
        Card(
            question: "Does anything ever go down?",
            answer: "No. Nothing here is a streak.",
            detail: "Reps only ever accumulate. A missed day doesn\u{2019}t break anything \u{2014} the cycle moves on and you rejoin it. A big manifestation might run twelve chapters, and that isn\u{2019}t failure; it\u{2019}s twelve chapters of evidence."
        ),
        Card(
            question: "When is it supposed to arrive?",
            answer: "Whenever it arrives. The full moon is a review, not a deadline.",
            detail: "What you read back at the full moon is the month\u{2019}s movement \u{2014} the signs, the nudges, the doors that opened. For anything large that\u{2019}s \u{201C}they emailed back\u{201D}, not \u{201C}I have it\u{201D}. You mark it Received the day it actually lands, in any phase, of any cycle."
        )
    ]

    // MARK: - Empty states

    static let noIntentions = "Nothing written down yet. A thought stays a thought until it has ink on it."
    static let noEvidence = "No evidence logged. Start noticing — it's already happening, you're just not writing it down."
    static let noScripts = "Nothing scripted yet. Write from a day that hasn't happened, in the past tense."
    static let noReceived = "Nothing archived yet. This fills up. Give it time."
}
