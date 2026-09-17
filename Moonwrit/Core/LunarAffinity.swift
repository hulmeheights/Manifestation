//
//  LunarAffinity.swift
//  Moonwrit
//
//  Which nights suit YOUR line, rather than nights in the abstract.
//
//  A wealth intention and a health intention are not worked the same way in
//  the traditional framework: one is about drawing something in, the other is
//  usually about clearing something out. So the app shouldn't give everybody
//  the same advice on the same night — it should look at what you're actually
//  running and say "this night, specifically, is your night."
//

import Foundation

extension LifeArea {

    /// The kind of lunar work this area is traditionally strongest on.
    var primaryWork: LunarWork {
        switch self {
        case .wealth:    return .set        // drawing in — ask on an empty sky
        case .love:      return .receive    // opening — full light
        case .health:    return .release    // clearing — waning
        case .work:      return .build      // momentum — waxing
        case .home:      return .set        // rooting — new moon
        case .spirit:    return .receive    // listening — full moon
        case .adventure: return .build      // motion — waxing
        case .freedom:   return .release     // cutting loose — waning
        }
    }

    /// The phase this area is at its strongest on, and why, in one line.
    var strongestPhase: MoonPhaseName {
        switch primaryWork {
        case .set, .rest:        return .newMoon
        case .build, .push:      return .waxingGibbous
        case .receive, .thank:   return .fullMoon
        case .release:           return .lastQuarter
        }
    }

    /// Why this area sits where it does — shown under your own line.
    var affinityReason: String {
        switch self {
        case .wealth:
            return "Money lines are asking lines, and tradition puts asking on the empty sky. Set it at the new moon and press hardest through the waxing week, when the light is climbing rather than going."
        case .love:
            return "Love lines are receiving lines. The full moon is your night — everything lit, nothing hidden. Read your evidence back then and you'll notice how much has already arrived."
        case .health:
            return "Health lines are usually clearing lines before they're building ones. The waning half is your stretch: put down what isn't helping, then let the body do what it does without being watched."
        case .work:
            return "Work lines run on momentum. The waxing week is yours — first quarter especially, which is where resistance shows up and most people quietly stop."
        case .home:
            return "Home lines are rooting lines. Set them at the new moon and leave them alone; roots don't grow faster for being dug up and checked."
        case .spirit:
            return "Spirit lines are listening lines rather than asking ones. The full moon is your night, and the dark days before the new moon are your second — the quiet is the point."
        case .adventure:
            return "Adventure lines want motion. The waxing half is yours, and the first quarter is where you do the thing that scares you slightly."
        case .freedom:
            return "Freedom lines are cutting-loose lines. The waning half is your stretch — the last quarter especially, for naming what you're finished carrying."
        }
    }

    /// Does this night suit this area particularly?
    func favours(_ phase: MoonPhaseName) -> Bool {
        phase.power.best == primaryWork
    }
}

// MARK: - Personalised reading

struct NightGuidance {
    let strength: Int
    /// True when this night is particularly yours.
    let personal: Bool
    let headline: String
    let body: String
    let against: String
}

extension MoonMoment {

    /// What tonight means for a particular intention.
    func guidance(for intention: Intention?) -> NightGuidance {
        let base = power
        let strength = strengthTonight

        guard let intention else {
            return NightGuidance(
                strength: strength,
                personal: false,
                headline: base.headline,
                body: base.why,
                against: base.against
            )
        }

        let area = intention.area
        let personal = area.favours(phase)

        var body = base.why
        if let extra = amplifiedTonight {
            body = extra + "\n\n" + body
        }

        if personal {
            return NightGuidance(
                strength: min(5, strength + 1),
                personal: true,
                headline: "Tonight is a \(area.title.lowercased()) night, and yours is a \(area.title.lowercased()) line.",
                body: area.affinityReason + "\n\n" + body,
                against: base.against
            )
        }

        return NightGuidance(
            strength: strength,
            personal: false,
            headline: base.headline,
            body: body,
            against: base.against
        )
    }
}

// MARK: - When to turn up

struct KeyNight: Identifiable {
    let id: String
    let date: Date
    let title: String
    let why: String
    let personal: Bool
    let strength: Int

    var nightsAway: Int {
        Int((date.timeIntervalSince(Date()) / 86_400).rounded(.up))
    }

    var whenLabel: String {
        let days = nightsAway
        if Calendar.current.isDateInToday(date) { return "TONIGHT" }
        if days == 1 { return "TOMORROW" }
        if days < 0 { return "PASSED" }
        if days < 14 { return "IN \(days) NIGHTS" }
        return date.formatted(.dateTime.day().month(.abbreviated)).uppercased()
    }
}

enum LunarPlanner {

    /// The nights to actually turn up for, given what you're running.
    static func keyNights(for intention: Intention?, months: Int = 6) -> [KeyNight] {
        let area = intention?.area
        return MoonAlmanac.upcoming(months: months).map { night in
            let moment = MoonPhase.moment(night.date)
            let personal = area.map { $0.favours(moment.phase) } ?? false
            let strength = max(1, min(5,
                moment.phase.power.strength + night.event.amplifier + (personal ? 1 : 0)
            ))

            var why = night.event.amplified ?? moment.phase.power.headline
            if personal, let area {
                why = "Your \(area.title.lowercased()) line is strongest on nights like this. " + why
            }

            return KeyNight(
                id: night.id,
                date: night.date,
                title: night.title,
                why: why,
                personal: personal,
                strength: strength
            )
        }
    }

    /// The single next night worth planning around.
    static func nextBigOne(for intention: Intention?) -> KeyNight? {
        keyNights(for: intention, months: 8).first {
            $0.nightsAway > 0 && ($0.strength >= 4 || $0.personal)
        }
    }
}
