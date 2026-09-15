//
//  Models.swift
//  Lumen
//
//  The vocabulary of the app. Everything the user writes down lives here.
//

import Foundation
import SwiftUI

// MARK: - Forgiving decoding
//
// The app is going to grow. Rather than break somebody's saved practice every
// time a field is added, every model decodes leniently: missing keys fall back
// to a default instead of throwing.

extension KeyedDecodingContainer {
    // `try?` flattens the optional, so `decodeIfPresent` comes back as a plain
    // `T?` here — one unwrap, not two.
    func get<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        if let value = try? decodeIfPresent(T.self, forKey: key) { return value }
        return fallback
    }

    func maybe<T: Decodable>(_ key: Key) -> T? {
        try? decodeIfPresent(T.self, forKey: key)
    }
}

// MARK: - Life areas

enum LifeArea: String, Codable, CaseIterable, Identifiable, Hashable {
    case wealth, love, health, work, home, spirit, adventure, freedom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wealth:    return "Abundance"
        case .love:      return "Love"
        case .health:    return "Body"
        case .work:      return "Craft"
        case .home:      return "Home"
        case .spirit:    return "Spirit"
        case .adventure: return "Adventure"
        case .freedom:   return "Freedom"
        }
    }

    var symbol: String {
        switch self {
        case .wealth:    return "crown.fill"
        case .love:      return "heart.fill"
        case .health:    return "leaf.fill"
        case .work:      return "briefcase.fill"
        case .home:      return "house.fill"
        case .spirit:    return "moon.stars.fill"
        case .adventure: return "airplane"
        case .freedom:   return "infinity"
        }
    }

    var tint: Color {
        switch self {
        case .wealth:    return Palette.gold
        case .love:      return Palette.rose
        case .health:    return Palette.teal
        case .work:      return Palette.violet
        case .home:      return Palette.amber
        case .spirit:    return Palette.lilac
        case .adventure: return Palette.sky
        case .freedom:   return Palette.mint
        }
    }

    /// A starting line offered during onboarding, already in the received tense.
    var seedAffirmation: String {
        switch self {
        case .wealth:    return "Money finds me easily and often"
        case .love:      return "I am deeply loved exactly as I am"
        case .health:    return "My body is strong, rested and well"
        case .work:      return "My work is seen and generously rewarded"
        case .home:      return "I live in a home that feels like peace"
        case .spirit:    return "I am guided, and I trust what I am given"
        case .adventure: return "The world opens itself to me"
        case .freedom:   return "My time belongs to me"
        }
    }
}

// MARK: - Intention

enum IntentionStage: String, Codable, CaseIterable, Identifiable, Hashable {
    case planted, inMotion, received

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planted:  return "Planted"
        case .inMotion: return "In motion"
        case .received: return "Received"
        }
    }

    var symbol: String {
        switch self {
        case .planted:  return "circle.dotted"
        case .inMotion: return "arrow.triangle.2.circlepath"
        case .received: return "checkmark.seal.fill"
        }
    }
}

/// How much energy an intention has gathered, purely from repetition.
enum Charge: Int, Comparable, CaseIterable {
    case seeded, anchored, magnetised, inevitable

    static func < (lhs: Charge, rhs: Charge) -> Bool { lhs.rawValue < rhs.rawValue }

    static func forReps(_ reps: Int) -> Charge {
        switch reps {
        case ..<33:   return .seeded
        case ..<99:   return .anchored
        case ..<369:  return .magnetised
        default:      return .inevitable
        }
    }

    var title: String {
        switch self {
        case .seeded:     return "Seeded"
        case .anchored:   return "Anchored"
        case .magnetised: return "Magnetised"
        case .inevitable: return "Inevitable"
        }
    }

    /// Reps required to reach this tier.
    var threshold: Int {
        switch self {
        case .seeded:     return 0
        case .anchored:   return 33
        case .magnetised: return 99
        case .inevitable: return 369
        }
    }

    var next: Charge? {
        switch self {
        case .seeded:     return .anchored
        case .anchored:   return .magnetised
        case .magnetised: return .inevitable
        case .inevitable: return nil
        }
    }

    var blurb: String {
        switch self {
        case .seeded:     return "Newly written. Keep saying it until it stops feeling like a lie."
        case .anchored:   return "It has taken root. You believe it a little more than you did."
        case .magnetised: return "You think it without trying now. Watch what starts arriving."
        case .inevitable: return "Three hundred and sixty-nine. This one is no longer a question."
        }
    }
}

struct Intention: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    /// Written in the present tense, as though already true.
    var affirmation: String = ""
    var area: LifeArea = .spirit
    /// The feeling it gives you to already have it — the part that does the work.
    var feeling: String = ""
    var detail: String = ""
    var byDate: Date?
    var stage: IntentionStage = .planted
    var reps: Int = 0
    var isFocus: Bool = false
    var createdAt: Date = Date()
    var receivedAt: Date?

    init(
        id: UUID = UUID(),
        affirmation: String = "",
        area: LifeArea = .spirit,
        feeling: String = "",
        detail: String = "",
        byDate: Date? = nil,
        stage: IntentionStage = .planted,
        reps: Int = 0,
        isFocus: Bool = false,
        createdAt: Date = Date(),
        receivedAt: Date? = nil
    ) {
        self.id = id
        self.affirmation = affirmation
        self.area = area
        self.feeling = feeling
        self.detail = detail
        self.byDate = byDate
        self.stage = stage
        self.reps = reps
        self.isFocus = isFocus
        self.createdAt = createdAt
        self.receivedAt = receivedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = c.get(.id, UUID())
        affirmation = c.get(.affirmation, "")
        area        = c.get(.area, LifeArea.spirit)
        feeling     = c.get(.feeling, "")
        detail      = c.get(.detail, "")
        byDate      = c.maybe(.byDate)
        stage       = c.get(.stage, IntentionStage.planted)
        reps        = c.get(.reps, 0)
        isFocus     = c.get(.isFocus, false)
        createdAt   = c.get(.createdAt, Date())
        receivedAt  = c.maybe(.receivedAt)
    }

    var charge: Charge { Charge.forReps(reps) }

    /// 0…1 progress toward the next charge tier.
    var chargeProgress: Double {
        guard let next = charge.next else { return 1 }
        let floorValue = Double(charge.threshold)
        let ceilingValue = Double(next.threshold)
        guard ceilingValue > floorValue else { return 1 }
        return min(1, max(0, (Double(reps) - floorValue) / (ceilingValue - floorValue)))
    }

    var daysHeld: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
}

// MARK: - Evidence

/// Proof that something is listening. The whole point of keeping it is that
/// doubt has a very short memory and this does not.
enum EvidenceKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case sign, synchronicity, nudge, win, received

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sign:          return "Sign"
        case .synchronicity: return "Synchronicity"
        case .nudge:         return "Nudge"
        case .win:           return "Win"
        case .received:      return "Received"
        }
    }

    var symbol: String {
        switch self {
        case .sign:          return "sparkles"
        case .synchronicity: return "arrow.triangle.2.circlepath"
        case .nudge:         return "bolt.fill"
        case .win:           return "checkmark.seal.fill"
        case .received:      return "gift.fill"
        }
    }

    var tint: Color {
        switch self {
        case .sign:          return Palette.gold
        case .synchronicity: return Palette.lilac
        case .nudge:         return Palette.sky
        case .win:           return Palette.mint
        case .received:      return Palette.rose
        }
    }

    var prompt: String {
        switch self {
        case .sign:          return "Repeating numbers, a song, a feather, the same word twice in a day."
        case .synchronicity: return "Two things lining up that had no business lining up."
        case .nudge:         return "A thought that arrived on its own. Write it before it goes."
        case .win:           return "Something went your way, however small."
        case .received:      return "It came. Write down exactly how."
        }
    }
}

struct EvidenceEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: EvidenceKind = .sign
    var text: String = ""
    var intentionID: UUID?
    var date: Date = Date()

    init(
        id: UUID = UUID(),
        kind: EvidenceKind = .sign,
        text: String = "",
        intentionID: UUID? = nil,
        date: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.intentionID = intentionID
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = c.get(.id, UUID())
        kind        = c.get(.kind, EvidenceKind.sign)
        text        = c.get(.text, "")
        intentionID = c.maybe(.intentionID)
        date        = c.get(.date, Date())
    }
}

// MARK: - Scripting

/// A letter written from a date that hasn't happened yet, in the past tense.
struct ScriptEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var body: String = ""
    var writtenFrom: Date = Date()
    var intentionID: UUID?
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        writtenFrom: Date = Date(),
        intentionID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.writtenFrom = writtenFrom
        self.intentionID = intentionID
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = c.get(.id, UUID())
        title       = c.get(.title, "")
        body        = c.get(.body, "")
        writtenFrom = c.get(.writtenFrom, Date())
        intentionID = c.maybe(.intentionID)
        createdAt   = c.get(.createdAt, Date())
    }
}

// MARK: - Ritual

/// Tesla's 3-6-9: three in the morning, six at midday, nine at night.
enum RitualWindow: String, Codable, CaseIterable, Identifiable, Hashable {
    case morning, afternoon, night

    var id: String { rawValue }

    var reps: Int {
        switch self {
        case .morning:   return 3
        case .afternoon: return 6
        case .night:     return 9
        }
    }

    var title: String {
        switch self {
        case .morning:   return "Morning"
        case .afternoon: return "Midday"
        case .night:     return "Night"
        }
    }

    var symbol: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .night:     return "moon.stars.fill"
        }
    }

    var instruction: String {
        switch self {
        case .morning:   return "Three times, before the day has an opinion."
        case .afternoon: return "Six times, in the middle of everything."
        case .night:     return "Nine times, the last thing you hand your sleeping mind."
        }
    }

    var notificationBody: String {
        switch self {
        case .morning:   return "Three lines. Set the tone before the world does."
        case .afternoon: return "Six lines. Come back to it."
        case .night:     return "Nine lines. Hand it over and sleep."
        }
    }
}

struct RitualRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var window: RitualWindow = .morning
    var intentionID: UUID?
    var reps: Int = 0

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        window: RitualWindow = .morning,
        intentionID: UUID? = nil,
        reps: Int = 0
    ) {
        self.id = id
        self.date = date
        self.window = window
        self.intentionID = intentionID
        self.reps = reps
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = c.get(.id, UUID())
        date        = c.get(.date, Date())
        window      = c.get(.window, RitualWindow.morning)
        intentionID = c.maybe(.intentionID)
        reps        = c.get(.reps, 0)
    }
}

// MARK: - Profile

struct Profile: Codable, Hashable {
    var name: String = ""
    var hasOnboarded: Bool = false
    var morningHour: Int = 7
    var afternoonHour: Int = 13
    var nightHour: Int = 21
    var notificationsEnabled: Bool = false
    var hapticsEnabled: Bool = true
    /// Accessibility: complete reps with a tap instead of typing them out.
    var tapToComplete: Bool = false
    var calmMotion: Bool = false
    var startedAt: Date = Date()

    // MARK: Moonlight

    /// Day, night, or following your own three windows.
    var appearance: Appearance = .auto

    // MARK: The Picture
    //
    // Visualisation is never forced and never on a countdown. The user moves
    // when they're ready; a clock counts up so slowness is rewarded rather
    // than punished.

    /// Play the affirmation back in the user's own recorded voice at the end.
    var playOwnVoice: Bool = true
    /// Show the elapsed clock during a session.
    var showVisualisationClock: Bool = true

    /// Everything unlocked, no subscription. Set on your own devices so you
    /// never pay for your own app.
    var ownerUnlocked: Bool = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name                 = c.get(.name, "")
        hasOnboarded         = c.get(.hasOnboarded, false)
        morningHour          = c.get(.morningHour, 7)
        afternoonHour        = c.get(.afternoonHour, 13)
        nightHour            = c.get(.nightHour, 21)
        notificationsEnabled = c.get(.notificationsEnabled, false)
        hapticsEnabled       = c.get(.hapticsEnabled, true)
        tapToComplete        = c.get(.tapToComplete, false)
        calmMotion           = c.get(.calmMotion, false)
        startedAt            = c.get(.startedAt, Date())
        appearance           = c.get(.appearance, Appearance.auto)
        playOwnVoice         = c.get(.playOwnVoice, true)
        showVisualisationClock = c.get(.showVisualisationClock, true)
        ownerUnlocked        = c.get(.ownerUnlocked, false)
    }

    /// The skin to draw with right now, honouring the user's own hours.
    var skin: Skin {
        Skin.of(appearance, nightHour: nightHour, morningHour: morningHour)
    }

    func hour(for window: RitualWindow) -> Int {
        switch window {
        case .morning:   return morningHour
        case .afternoon: return afternoonHour
        case .night:     return nightHour
        }
    }
}

// MARK: - Everything, on disk

struct ManifestState: Codable {
    var profile: Profile = Profile()
    var intentions: [Intention] = []
    var evidence: [EvidenceEntry] = []
    var scripts: [ScriptEntry] = []
    var rituals: [RitualRecord] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile    = c.get(.profile, Profile())
        intentions = c.get(.intentions, [Intention]())
        evidence   = c.get(.evidence, [EvidenceEntry]())
        scripts    = c.get(.scripts, [ScriptEntry]())
        rituals    = c.get(.rituals, [RitualRecord]())
    }
}
