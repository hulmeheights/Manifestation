//
//  MoonPhase.swift
//  Moonwrit
//
//  The lunar cycle, computed. No API, no network, no dependency — the moon
//  is arithmetic on a date, so this works offline and forever.
//
//  Phase instants use the truncated Meeus algorithm (Astronomical Algorithms,
//  ch. 49), which is accurate to a couple of minutes. Illumination is derived
//  from the position within the lunation, which is accurate to well under a
//  percent — far finer than anything we draw.
//

import Foundation

// MARK: - The eight phases

enum MoonPhaseName: String, Codable, CaseIterable, Identifiable, Hashable {
    case newMoon, waxingCrescent, firstQuarter, waxingGibbous
    case fullMoon, waningGibbous, lastQuarter, waningCrescent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newMoon:         return "New moon"
        case .waxingCrescent:  return "Waxing crescent"
        case .firstQuarter:    return "First quarter"
        case .waxingGibbous:   return "Waxing gibbous"
        case .fullMoon:        return "Full moon"
        case .waningGibbous:   return "Waning gibbous"
        case .lastQuarter:     return "Last quarter"
        case .waningCrescent:  return "Waning crescent"
        }
    }

    /// What the app asks of you in this phase.
    var verb: String {
        switch self {
        case .newMoon:        return "Plant"
        case .waxingCrescent: return "Build"
        case .firstQuarter:   return "Build"
        case .waxingGibbous:  return "Press"
        case .fullMoon:       return "Read"
        case .waningGibbous:  return "Thank"
        case .lastQuarter:    return "Thank"
        case .waningCrescent: return "Hands off"
        }
    }

    var isWaxing: Bool {
        switch self {
        case .newMoon, .waxingCrescent, .firstQuarter, .waxingGibbous: return true
        case .fullMoon, .waningGibbous, .lastQuarter, .waningCrescent: return false
        }
    }

    /// The app's own chapter stages, mapped onto the eight phases.
    var stage: CycleStage {
        switch self {
        case .newMoon:                        return .plant
        case .waxingCrescent, .firstQuarter:  return .build
        case .waxingGibbous:                  return .press
        case .fullMoon:                       return .read
        case .waningGibbous, .lastQuarter:    return .thank
        case .waningCrescent:                 return .release
        }
    }
}

enum CycleStage: String, Codable, CaseIterable, Identifiable, Hashable {
    case plant, build, press, read, thank, release

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plant:   return "Write it down"
        case .build:   return "Start the reps"
        case .press:   return "Hold the line"
        case .read:    return "Read the month back"
        case .thank:   return "Script it forward"
        case .release: return "Stop checking"
        }
    }

    var blurb: String {
        switch self {
        case .plant:
            return "A fresh chapter. Confirm the line you're running, or write a new one."
        case .build:
            return "Three, six, nine. Light touch — the number you see is what you've put in."
        case .press:
            return "Peak density. This is where the charge is won."
        case .read:
            return "Everything that arrived this chapter, in one sitting. Look what moved."
        case .thank:
            return "Write from a date ahead of you, in the past tense. Gratitude before delivery."
        case .release:
            return "You've sent it. Checking whether it worked is doubt in a nice coat."
        }
    }
}

// MARK: - A moment in the cycle

struct MoonMoment: Hashable {
    /// The moment this was computed for.
    let date: Date
    /// Start of the lunation containing `date` (the new moon).
    let cycleStart: Date
    /// Start of the next lunation.
    let cycleEnd: Date
    /// The full moon within this lunation.
    let fullMoon: Date
    /// Days elapsed since the new moon.
    let age: Double
    /// Length of this particular lunation, in days.
    let cycleLength: Double
    /// 0 at new moon, 1 at full moon.
    let illumination: Double
    let phase: MoonPhaseName

    var isWaxing: Bool { phase.isWaxing }
    var stage: CycleStage { phase.stage }

    /// 1-based day of the cycle, for display: "day 11 of 29".
    var cycleDay: Int { max(1, Int(age.rounded(.down)) + 1) }
    var cycleDays: Int { max(1, Int(cycleLength.rounded())) }

    /// How far through the lunation, 0...1. Drives the phase strip.
    var progress: Double {
        guard cycleLength > 0 else { return 0 }
        return min(1, max(0, age / cycleLength))
    }

    var illuminationPercent: Int { Int((illumination * 100).rounded()) }

    /// Whole nights until the full moon; negative once it has passed.
    var nightsToFull: Int {
        let seconds = fullMoon.timeIntervalSince(date)
        return Int((seconds / 86_400).rounded(.up))
    }

    var nightsToNew: Int {
        let seconds = cycleEnd.timeIntervalSince(date)
        return Int((seconds / 86_400).rounded(.up))
    }

    /// The line shown under the moon on the cycle screen.
    var instruction: String {
        switch stage {
        case .plant:
            return "A new chapter. Confirm your line, or write a new one."
        case .build, .press:
            let n = nightsToFull
            if n <= 0 { return stage.blurb }
            return n == 1
                ? "Hold the line. One night until you read the month back."
                : "Hold the line. \(n) nights until you read the month back."
        case .read:
            return "Everything that arrived this chapter, in one sitting."
        case .thank:
            return "Write from a date ahead of you, in the past tense."
        case .release:
            let n = nightsToNew
            if n <= 0 { return stage.blurb }
            return n == 1
                ? "Hands off. One night until the next chapter."
                : "Hands off. \(n) nights until the next chapter."
        }
    }
}

// MARK: - The maths

enum MoonPhase {

    /// Mean length of a lunation, in days.
    static let synodicMonth: Double = 29.530588861

    /// Everything the app needs to know about the moon at `date`.
    static func moment(_ date: Date = Date()) -> MoonMoment {
        let jd = julianDay(date)

        // Walk back to the new moon at or before this moment.
        var k = (approximateK(jd)).rounded()
        var start = phaseInstant(k: k, quarter: 0)
        while start > jd {
            k -= 1
            start = phaseInstant(k: k, quarter: 0)
        }
        var next = phaseInstant(k: k + 1, quarter: 0)
        while next <= jd {
            k += 1
            start = next
            next = phaseInstant(k: k + 1, quarter: 0)
        }

        let full = phaseInstant(k: k, quarter: 0.5)
        let length = max(1, next - start)
        let age = max(0, jd - start)
        let fraction = min(1, age / length)

        // Illuminated fraction of the disc.
        let illum = (1 - cos(2 * Double.pi * fraction)) / 2

        return MoonMoment(
            date: date,
            cycleStart: dateFrom(julianDay: start),
            cycleEnd: dateFrom(julianDay: next),
            fullMoon: dateFrom(julianDay: full),
            age: age,
            cycleLength: length,
            illumination: illum,
            phase: name(forFraction: fraction)
        )
    }

    /// Convenience for the widget and the notification text.
    static func illumination(_ date: Date = Date()) -> Double {
        moment(date).illumination
    }

    // MARK: Phase naming
    //
    // The four exact phases get a window of roughly a day and a half either
    // side, so "full moon" is a night you can turn up for rather than an
    // instant you miss while asleep.

    static func name(forFraction f: Double) -> MoonPhaseName {
        let window = 1.5 / synodicMonth   // ± a day and a half, as a fraction
        switch f {
        case ..<window:                   return .newMoon
        case ..<(0.25 - window):          return .waxingCrescent
        case ..<(0.25 + window):          return .firstQuarter
        case ..<(0.5 - window):           return .waxingGibbous
        case ..<(0.5 + window):           return .fullMoon
        case ..<(0.75 - window):          return .waningGibbous
        case ..<(0.75 + window):          return .lastQuarter
        case ..<(1 - window):             return .waningCrescent
        default:                          return .newMoon
        }
    }

    // MARK: Julian day

    /// Julian Day for a Date. Unix epoch is JD 2440587.5.
    static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    static func dateFrom(julianDay jd: Double) -> Date {
        Date(timeIntervalSince1970: (jd - 2_440_587.5) * 86_400)
    }

    /// Rough lunation number since the new moon of 2000 January 6.
    private static func approximateK(_ jd: Double) -> Double {
        let year = 2000.0 + (jd - 2_451_545.0) / 365.25
        return (year - 2000) * 12.3685
    }

    // MARK: Meeus ch. 49
    //
    // `quarter` is 0 for a new moon and 0.5 for a full moon. The two share a
    // structure and differ only in the leading coefficients.

    private static func phaseInstant(k lunation: Double, quarter: Double) -> Double {
        let k = lunation + quarter
        let t = k / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        // Mean phase.
        var jde = 2_451_550.09766
            + 29.530588861 * k
            + 0.00015437 * t2
            - 0.000000150 * t3
            + 0.00000000073 * t4

        // Eccentricity of the Earth's orbit.
        let e = 1 - 0.002516 * t - 0.0000074 * t2

        // Sun's mean anomaly.
        let m = rad(2.5534 + 29.10535670 * k - 0.0000014 * t2 - 0.00000011 * t3)
        // Moon's mean anomaly.
        let mp = rad(201.5643 + 385.81693528 * k + 0.0107582 * t2
                     + 0.00001238 * t3 - 0.000000058 * t4)
        // Moon's argument of latitude.
        let f = rad(160.7108 + 390.67050284 * k - 0.0016118 * t2
                    - 0.00000227 * t3 + 0.000000011 * t4)
        // Longitude of the ascending node.
        let omega = rad(124.7746 - 1.56375588 * k + 0.0020672 * t2 + 0.00000215 * t3)

        let isFull = quarter == 0.5
        let c1 = isFull ? -0.40614 : -0.40720
        let c2 = isFull ?  0.17302 :  0.17241
        let c3 = isFull ?  0.01614 :  0.01608
        let c4 = isFull ?  0.01043 :  0.01039
        let c5 = isFull ?  0.00734 :  0.00739
        let c6 = isFull ? -0.00515 : -0.00514
        let c7 = isFull ?  0.00209 :  0.00208

        jde += c1 * sin(mp)
        jde += c2 * e * sin(m)
        jde += c3 * sin(2 * mp)
        jde += c4 * sin(2 * f)
        jde += c5 * e * sin(mp - m)
        jde += c6 * e * sin(mp + m)
        jde += c7 * e * e * sin(2 * m)
        jde += -0.00111 * sin(mp - 2 * f)
        jde += -0.00057 * sin(mp + 2 * f)
        jde +=  0.00056 * e * sin(2 * mp + m)
        jde += -0.00042 * sin(3 * mp)
        jde +=  0.00042 * e * sin(m + 2 * f)
        jde +=  0.00038 * e * sin(m - 2 * f)
        jde += -0.00024 * e * sin(2 * mp - m)
        jde += -0.00017 * sin(omega)
        jde += -0.00007 * sin(mp + 2 * m)

        return jde
    }

    private static func rad(_ degrees: Double) -> Double {
        degrees.truncatingRemainder(dividingBy: 360) * Double.pi / 180
    }
}

// MARK: - Chapters
//
// A chapter is one lunation's worth of practice on the intention that is
// currently in the light. Intentions persist across as many chapters as they
// take; the chapter is the unit of *work*, never a deadline.

struct Chapter: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    /// The new moon this chapter began on.
    var startedAt: Date = Date()
    /// The intention that held the light for it.
    var intentionID: UUID?
    /// Reps written during this chapter.
    var reps: Int = 0
    /// Evidence logged during this chapter.
    var evidenceCount: Int = 0
    /// Doors opened during this chapter.
    var doorsOpened: Int = 0

    /// "September", for the chapter list.
    var label: String {
        startedAt.formatted(.dateTime.month(.abbreviated)).uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case id, startedAt, intentionID, reps, evidenceCount, doorsOpened
    }

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        intentionID: UUID? = nil,
        reps: Int = 0,
        evidenceCount: Int = 0,
        doorsOpened: Int = 0
    ) {
        self.id = id
        self.startedAt = startedAt
        self.intentionID = intentionID
        self.reps = reps
        self.evidenceCount = evidenceCount
        self.doorsOpened = doorsOpened
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        startedAt     = (try? c.decode(Date.self, forKey: .startedAt)) ?? Date()
        intentionID   = try? c.decode(UUID.self, forKey: .intentionID)
        reps          = (try? c.decode(Int.self, forKey: .reps)) ?? 0
        evidenceCount = (try? c.decode(Int.self, forKey: .evidenceCount)) ?? 0
        doorsOpened   = (try? c.decode(Int.self, forKey: .doorsOpened)) ?? 0
    }
}
