//
//  MoonPower.swift
//  Lumen
//
//  When the practice is supposed to bite hardest, and what kind of work each
//  night is actually for.
//
//  A note on honesty, because it matters: none of this is physics. It is the
//  traditional lunar framework people have practised by for a very long time,
//  and the app states it as exactly that. What IS demonstrably true is that a
//  practice with a rhythm gets done and a practice without one doesn't — so
//  knowing that tonight is a night for asking, and next Thursday is a night
//  for letting go, is worth having whether or not the moon is doing anything
//  to you. The app never claims a mechanism it can't stand behind.
//

import Foundation

/// The kind of work a night suits.
enum LunarWork: String, CaseIterable, Identifiable, Hashable {
    case set        // write it down, ask
    case build      // reps, momentum
    case push       // through the wall
    case receive    // read the evidence back
    case thank      // gratitude, scripting
    case release    // let go of what's held you
    case rest       // ask for nothing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .set:     return "Setting"
        case .build:   return "Building"
        case .push:    return "Pushing"
        case .receive: return "Receiving"
        case .thank:   return "Thanking"
        case .release: return "Releasing"
        case .rest:    return "Resting"
        }
    }
}

struct MoonPower {
    /// 1–5. How much weight tradition puts on tonight.
    let strength: Int
    let best: LunarWork
    /// The headline: what tonight is for.
    let headline: String
    /// Why, in the app's voice.
    let why: String
    /// The one thing not to do tonight.
    let against: String

    var strengthLabel: String {
        switch strength {
        case 5: return "Strongest night of the cycle"
        case 4: return "A strong night"
        case 3: return "An ordinary working night"
        case 2: return "A quiet night"
        default: return "A resting night"
        }
    }
}

extension MoonPhaseName {

    var power: MoonPower {
        switch self {
        case .newMoon:
            return MoonPower(
                strength: 5,
                best: .set,
                headline: "The best night of the month to ask for something new.",
                why: "Nothing is lit. Traditionally this is the empty page — the moment to name what you actually want rather than tidy up what you already asked for. Anything you set tonight has a whole cycle to grow into.",
                against: "Don't check whether the last thing worked. Nothing has had time."
            )

        case .waxingCrescent:
            return MoonPower(
                strength: 3,
                best: .build,
                headline: "Early days. Put the reps in and don't look for results.",
                why: "The light is returning but there's barely any of it. This is the stretch where a practice is won or quietly abandoned, and nothing visible happens either way.",
                against: "Don't add a second intention because the first feels slow. It's meant to."
            )

        case .firstQuarter:
            return MoonPower(
                strength: 4,
                best: .push,
                headline: "The wall. Push through it tonight and the rest of the cycle is easy.",
                why: "Half lit, half dark — traditionally the point of friction, where resistance shows up and most people stop. Doing the nine tonight specifically is worth more than doing them on an easy night.",
                against: "Don't rewrite your line because it's getting hard. Hard is the schedule, not a sign."
            )

        case .waxingGibbous:
            return MoonPower(
                strength: 4,
                best: .build,
                headline: "Nearly full. Press — this is where the charge is won.",
                why: "The heaviest working stretch of the cycle. Whatever you put in now is what you'll be reading back in a few nights, so this is the week to be stubborn about the nine.",
                against: "Don't ease off because the full moon is close. That's the whole point of it being close."
            )

        case .fullMoon:
            return MoonPower(
                strength: 5,
                best: .receive,
                headline: "Everything is lit. Read the month back, then let it go.",
                why: "The most charged night in the month and the only one the app really asks you to turn up for. Read every piece of evidence since the new moon in one sitting — that's the night's actual work. Then release your grip on the outcome.",
                against: "Don't set something new tonight. Full moons are for receiving, not asking — save it for the new moon."
            )

        case .waningGibbous:
            return MoonPower(
                strength: 3,
                best: .thank,
                headline: "Say thank you for it as though it's already yours.",
                why: "The light is going. Traditionally the gratitude stretch — write from a date ahead of you, in the past tense, as someone who already has it and is looking back.",
                against: "Don't start counting the days. Counting is doubt with a calendar."
            )

        case .lastQuarter:
            return MoonPower(
                strength: 3,
                best: .release,
                headline: "Put down whatever you've been carrying that isn't helping.",
                why: "Half dark now. The traditional night for cutting something loose — a habit, a grudge, a story about yourself that keeps the thing at arm's length.",
                against: "Don't take on anything new. There's nowhere for it to go this cycle."
            )

        case .waningCrescent:
            return MoonPower(
                strength: 2,
                best: .rest,
                headline: "Hands off. Ask for nothing and let it be handled.",
                why: "The last of the light. You've sent it — checking whether it worked is doubt in a nice coat, and this is the week the app deliberately goes quiet so you're not refreshing for an answer.",
                against: "Don't ask for anything. Not tonight. It'll keep four days."
            )
        }
    }
}

extension MoonEvent {

    /// How much this event lifts an ordinary night.
    var amplifier: Int {
        switch self {
        case .totalLunarEclipse: return 2
        case .solarEclipse:      return 2
        case .lunarEclipse:      return 1
        case .superFullMoon:     return 1
        case .blueMoon:          return 1
        case .fullMoon, .newMoon: return 0
        case .microFullMoon:     return -1
        }
    }

    /// What this specific night is for, beyond the ordinary phase.
    var amplified: String? {
        switch self {
        case .superFullMoon:
            return "The moon is at its closest all year. Tradition says ask for the whole thing tonight, not a sensible portion of it."
        case .microFullMoon:
            return "The furthest, faintest full moon. Still a receiving night, just a softer one — gratitude over asking."
        case .blueMoon:
            return "A second full moon in one month, which happens roughly every two and a half years. A free extra chapter you weren't scheduled to get."
        case .lunarEclipse:
            return "The Earth's shadow crosses the moon. Traditionally a night for endings — name what you're finished with."
        case .totalLunarEclipse:
            return "The moon turns copper in the Earth's shadow. The most charged night in the lunar year: release first, then ask once, clearly, and don't ask again."
        case .solarEclipse:
            return "A new moon strong enough to hide the sun. For beginnings you're willing to be patient about — things that take six months to show up, not six days."
        case .fullMoon, .newMoon:
            return nil
        }
    }
}

extension MoonMoment {

    var power: MoonPower { phase.power }

    /// Strength, lifted by anything special happening tonight.
    var strengthTonight: Int {
        let event = MoonAlmanac.tonight(date)?.event
        return max(1, min(5, power.strength + (event?.amplifier ?? 0)))
    }

    /// The extra line when tonight is more than an ordinary phase.
    var amplifiedTonight: String? {
        MoonAlmanac.tonight(date)?.event.amplified
    }
}
