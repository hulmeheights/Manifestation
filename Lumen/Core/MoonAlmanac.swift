//
//  MoonAlmanac.swift
//  Lumen
//
//  The moon does more than turn over every twenty-nine days. Some nights
//  carry far more weight than others, and a practice that only knows "day 11"
//  is missing most of what's actually happening overhead.
//
//  Everything here that can be computed, is computed. Eclipses can't be —
//  properly predicting them needs a full solar and lunar ephemeris — so they
//  come from a small bundled table, which is honest and exact rather than
//  approximate and wrong.
//

import Foundation

// MARK: - What makes a night special

enum MoonEvent: String, Codable, CaseIterable, Identifiable, Hashable {
    case newMoon
    case fullMoon
    case superFullMoon
    case microFullMoon
    case blueMoon
    case lunarEclipse
    case totalLunarEclipse      // the blood moon
    case solarEclipse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newMoon:          return "New moon"
        case .fullMoon:         return "Full moon"
        case .superFullMoon:    return "Supermoon"
        case .microFullMoon:    return "Micromoon"
        case .blueMoon:         return "Blue moon"
        case .lunarEclipse:     return "Partial lunar eclipse"
        case .totalLunarEclipse:return "Blood moon"
        case .solarEclipse:     return "Solar eclipse"
        }
    }

    /// What the app asks of you on that night. This is the whole point of
    /// knowing — otherwise it's trivia.
    var practice: String {
        switch self {
        case .newMoon:
            return "The cleanest night of the month to set something down. Write the line you mean to run, or rewrite the one you have."
        case .fullMoon:
            return "Read the month back. Everything that arrived since the new moon, in one sitting."
        case .superFullMoon:
            return "The moon is at its closest and brightest of the year. Traditionally the night to ask for the biggest version of the thing \u{2014} not a careful version of it."
        case .microFullMoon:
            return "The furthest, faintest full moon. A quieter night \u{2014} good for gratitude rather than asking."
        case .blueMoon:
            return "A second full moon in one month, which happens about every two and a half years. A free extra chapter."
        case .lunarEclipse:
            return "The Earth's shadow crosses the moon. Traditionally a night for endings \u{2014} mark what you're finished with."
        case .totalLunarEclipse:
            return "The moon turns copper in the Earth's shadow. The most charged night in the lunar year: release what's held you, then ask once, clearly."
        case .solarEclipse:
            return "A new moon strong enough to hide the sun. Beginnings that will take a long time to arrive \u{2014} set something you're willing to be patient about."
        }
    }

    var weight: Int {
        switch self {
        case .totalLunarEclipse: return 5
        case .solarEclipse:      return 4
        case .lunarEclipse:      return 4
        case .superFullMoon:     return 3
        case .blueMoon:          return 3
        case .fullMoon:          return 2
        case .newMoon:           return 2
        case .microFullMoon:     return 1
        }
    }

    var isMajor: Bool { weight >= 3 }
}

struct MoonNight: Identifiable, Hashable {
    let id: String
    let date: Date
    let event: MoonEvent
    /// The traditional name for that month's full moon, where there is one.
    let seasonalName: String?

    var title: String {
        if let seasonalName, event == .fullMoon || event == .superFullMoon {
            return "\(seasonalName) \(event == .superFullMoon ? "supermoon" : "moon")"
        }
        return event.title
    }

    var nightsAway: Int {
        let days = date.timeIntervalSince(Date()) / 86_400
        return Int(days.rounded(.up))
    }

    var isTonight: Bool { Calendar.current.isDateInToday(date) }
}

// MARK: - The almanac

enum MoonAlmanac {

    /// Mean anomalistic month — perigee to perigee. Used to tell a supermoon
    /// from an ordinary full moon without a full ephemeris.
    private static let anomalisticMonth = 27.554549878

    /// A known perigee, as a Julian Day: 1997 Dec 9.
    private static let knownPerigee = 2_450_792.0

    /// Traditional names, by the month the full moon falls in.
    private static let fullMoonNames = [
        1: "Wolf", 2: "Snow", 3: "Worm", 4: "Pink", 5: "Flower", 6: "Strawberry",
        7: "Buck", 8: "Sturgeon", 9: "Harvest", 10: "Hunter", 11: "Beaver", 12: "Cold"
    ]

    /// Central eclipse dates, from published tables. Times are approximate to
    /// the day, which is all the app displays. Extend this list as needed.
    private static let eclipses: [(String, MoonEvent)] = [
        ("2026-02-17", .solarEclipse),
        ("2026-03-03", .totalLunarEclipse),
        ("2026-08-12", .solarEclipse),
        ("2026-08-28", .lunarEclipse),
        ("2027-02-06", .solarEclipse),
        ("2027-02-20", .lunarEclipse),
        ("2027-07-18", .lunarEclipse),
        ("2027-08-02", .solarEclipse),
        ("2027-08-17", .lunarEclipse),
        ("2028-01-12", .solarEclipse),
        ("2028-01-26", .lunarEclipse),
        ("2028-06-26", .totalLunarEclipse),
        ("2028-07-06", .solarEclipse),
        ("2028-12-20", .totalLunarEclipse),
        ("2028-12-31", .solarEclipse),
        ("2029-06-12", .solarEclipse),
        ("2029-06-26", .totalLunarEclipse),
        ("2029-12-05", .solarEclipse),
        ("2029-12-20", .totalLunarEclipse),
        ("2030-06-01", .solarEclipse),
        ("2030-06-15", .lunarEclipse),
        ("2030-11-25", .solarEclipse),
        ("2030-12-09", .lunarEclipse)
    ]

    private static let isoDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    // MARK: Upcoming

    /// Every notable night in the next `months` months, soonest first.
    static func upcoming(from start: Date = Date(), months: Int = 12) -> [MoonNight] {
        var nights: [MoonNight] = []
        let calendar = Calendar.current
        guard let horizon = calendar.date(byAdding: .month, value: months, to: start) else {
            return []
        }

        // New and full moons, walked forward lunation by lunation.
        var cursor = start
        var guard_ = 0
        var fullMoonMonths: [Int: Int] = [:]   // month key → count, for blue moons

        while cursor < horizon && guard_ < 40 {
            guard_ += 1
            let moment = MoonPhase.moment(cursor)

            let newMoon = moment.cycleEnd
            if newMoon > start && newMoon < horizon {
                nights.append(
                    MoonNight(
                        id: "new-\(newMoon.timeIntervalSince1970)",
                        date: newMoon,
                        event: .newMoon,
                        seasonalName: nil
                    )
                )
            }

            let full = moment.fullMoon
            if full > start && full < horizon {
                let month = calendar.component(.month, from: full)
                let year = calendar.component(.year, from: full)
                let key = year * 100 + month
                fullMoonMonths[key, default: 0] += 1

                let event: MoonEvent
                if fullMoonMonths[key] == 2 {
                    event = .blueMoon
                } else {
                    switch distanceClass(at: full) {
                    case .near: event = .superFullMoon
                    case .far:  event = .microFullMoon
                    case .mid:  event = .fullMoon
                    }
                }

                nights.append(
                    MoonNight(
                        id: "full-\(full.timeIntervalSince1970)",
                        date: full,
                        event: event,
                        seasonalName: fullMoonNames[month]
                    )
                )
            }

            // Step into the next lunation.
            cursor = moment.cycleEnd.addingTimeInterval(86_400)
        }

        // Eclipses, from the table.
        for (day, event) in eclipses {
            guard let date = isoDay.date(from: day), date > start, date < horizon else { continue }
            nights.append(
                MoonNight(id: "ecl-\(day)", date: date, event: event, seasonalName: nil)
            )
        }

        return nights.sorted { $0.date < $1.date }
    }

    /// The next night worth turning up for, ignoring ordinary full and new moons.
    static func nextMajor(from start: Date = Date()) -> MoonNight? {
        upcoming(from: start, months: 18).first { $0.event.isMajor }
    }

    /// Anything happening today.
    static func tonight(_ date: Date = Date()) -> MoonNight? {
        upcoming(from: Calendar.current.startOfDay(for: date).addingTimeInterval(-1), months: 2)
            .first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: How close the moon is

    private enum DistanceClass { case near, mid, far }

    /// Where the moon sits between perigee and apogee, 0 = closest.
    private static func distanceClass(at date: Date) -> DistanceClass {
        let jd = MoonPhase.julianDay(date)
        let sinceperigee = (jd - knownPerigee).truncatingRemainder(dividingBy: anomalisticMonth)
        let phase = (sinceperigee < 0 ? sinceperigee + anomalisticMonth : sinceperigee) / anomalisticMonth
        // 0 and 1 are perigee, 0.5 is apogee.
        let closeness = abs(cos(2 * Double.pi * phase))
        if phase < 0.12 || phase > 0.88 { return .near }
        if closeness < 0.18 { return .mid }
        return phase > 0.38 && phase < 0.62 ? .far : .mid
    }
}
