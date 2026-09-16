//
//  ManifestStore.swift
//  Lumen
//
//  One observable object holds the whole practice and writes it to disk.
//  Deliberately boring: a Codable blob, atomically written, debounced.
//  When this app earns iCloud sync, this is the single file that changes.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class ManifestStore {

    private(set) var state: ManifestState

    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private let io = DispatchQueue(label: "com.lumen.store", qos: .utility)
    @ObservationIgnored private var pendingSave: DispatchWorkItem?

    // MARK: - Lifecycle

    init(fileURL: URL? = nil, seed: ManifestState? = nil) {
        let url = fileURL ?? Self.defaultFileURL()
        self.fileURL = url
        self.state = seed ?? Self.load(from: url) ?? ManifestState()
    }

    private static func defaultFileURL() -> URL {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("lumen-practice.json")
    }

    private static func load(from url: URL) -> ManifestState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ManifestState.self, from: data)
    }

    /// Debounced write. Every mutation below funnels through here.
    private func scheduleSave() {
        pendingSave?.cancel()
        let snapshot = state
        let url = fileURL
        let work = DispatchWorkItem {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let data = try? encoder.encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
        pendingSave = work
        io.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    /// Called when the app is backgrounded — don't wait out the debounce.
    func flush() {
        pendingSave?.cancel()
        pendingSave = nil
        let snapshot = state
        let url = fileURL
        io.async {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let data = try? encoder.encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - Profile

    var profile: Profile {
        get { state.profile }
        set {
            state.profile = newValue
            scheduleSave()
        }
    }

    // MARK: - Becoming

    var character: CharacterSheet {
        get { state.character }
        set {
            state.character = newValue
            scheduleSave()
        }
    }

    /// Cast a vote. Doing the same act twice in one day counts once —
    /// the point is the day, not the tally.
    func castVote(act: Act, trait: Trait, note: String = "") {
        guard !state.character.didToday(act.id) else { return }
        state.character.votes.append(
            Vote(actID: act.id, traitID: trait.id, date: Date(), note: note)
        )
        scheduleSave()
    }

    /// Undo today's vote, for the times you ticked it and then didn't do it.
    func withdrawVote(actID: String) {
        let today = Date()
        state.character.votes.removeAll {
            $0.actID == actID && Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        scheduleSave()
    }

    // MARK: - Intentions

    var intentions: [Intention] { state.intentions }

    /// Focus first, then whatever has the most energy in it.
    var activeIntentions: [Intention] {
        state.intentions
            .filter { $0.stage != .received }
            .sorted { lhs, rhs in
                if lhs.isFocus != rhs.isFocus { return lhs.isFocus }
                if lhs.reps != rhs.reps { return lhs.reps > rhs.reps }
                return lhs.createdAt > rhs.createdAt
            }
    }

    var receivedIntentions: [Intention] {
        state.intentions
            .filter { $0.stage == .received }
            .sorted { ($0.receivedAt ?? $0.createdAt) > ($1.receivedAt ?? $1.createdAt) }
    }

    /// The one the rituals default to.
    var focusIntention: Intention? {
        state.intentions.first { $0.isFocus && $0.stage != .received } ?? activeIntentions.first
    }

    func intention(with id: UUID?) -> Intention? {
        guard let id else { return nil }
        return state.intentions.first { $0.id == id }
    }

    func add(_ intention: Intention) {
        var new = intention
        // First one in is automatically the focus.
        if state.intentions.allSatisfy({ $0.stage == .received }) { new.isFocus = true }
        if new.isFocus { clearFocusFlags(except: new.id) }
        state.intentions.append(new)
        scheduleSave()
    }

    func update(_ intention: Intention) {
        guard let index = state.intentions.firstIndex(where: { $0.id == intention.id }) else { return }
        if intention.isFocus { clearFocusFlags(except: intention.id) }
        state.intentions[index] = intention
        scheduleSave()
    }

    func delete(_ intention: Intention) {
        state.intentions.removeAll { $0.id == intention.id }
        state.evidence.removeAll { $0.intentionID == intention.id }
        state.rituals.removeAll { $0.intentionID == intention.id }
        for index in state.scripts.indices where state.scripts[index].intentionID == intention.id {
            state.scripts[index].intentionID = nil
        }
        scheduleSave()
    }

    func setFocus(_ intention: Intention) {
        clearFocusFlags(except: intention.id)
        if let index = state.intentions.firstIndex(where: { $0.id == intention.id }) {
            state.intentions[index].isFocus = true
        }
        scheduleSave()
    }

    private func clearFocusFlags(except id: UUID) {
        for index in state.intentions.indices where state.intentions[index].id != id {
            state.intentions[index].isFocus = false
        }
    }

    /// Mark it as landed. Files a piece of evidence at the same time, because
    /// the archive is the entire point of keeping one.
    func markReceived(_ intention: Intention, note: String = "") {
        guard let index = state.intentions.firstIndex(where: { $0.id == intention.id }) else { return }
        state.intentions[index].stage = .received
        state.intentions[index].receivedAt = Date()
        state.intentions[index].isFocus = false

        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        state.evidence.insert(
            EvidenceEntry(
                kind: .received,
                text: text.isEmpty ? intention.affirmation : text,
                intentionID: intention.id
            ),
            at: 0
        )
        scheduleSave()
    }

    func returnToActive(_ intention: Intention) {
        guard let index = state.intentions.firstIndex(where: { $0.id == intention.id }) else { return }
        state.intentions[index].stage = .inMotion
        state.intentions[index].receivedAt = nil
        scheduleSave()
    }

    // MARK: - Rituals

    /// Records a finished session and moves the intention's charge up.
    func recordRitual(intentionID: UUID, window: RitualWindow, reps: Int) {
        state.rituals.append(
            RitualRecord(date: Date(), window: window, intentionID: intentionID, reps: reps)
        )
        if let index = state.intentions.firstIndex(where: { $0.id == intentionID }) {
            state.intentions[index].reps += reps
            if state.intentions[index].stage == .planted {
                state.intentions[index].stage = .inMotion
            }
        }
        scheduleSave()
    }

    var todaysRituals: [RitualRecord] {
        let calendar = Calendar.current
        return state.rituals.filter { calendar.isDateInToday($0.date) }
    }

    func repsCompleted(in window: RitualWindow) -> Int {
        todaysRituals.filter { $0.window == window }.reduce(0) { $0 + $1.reps }
    }

    func isComplete(_ window: RitualWindow) -> Bool {
        repsCompleted(in: window) >= window.reps
    }

    var repsToday: Int {
        todaysRituals.reduce(0) { $0 + $1.reps }
    }

    /// 0…1 across the full 3 + 6 + 9.
    var todayProgress: Double {
        let target = RitualWindow.allCases.reduce(0) { $0 + $1.reps }
        let done = RitualWindow.allCases.reduce(0) { $0 + min(repsCompleted(in: $1), $1.reps) }
        guard target > 0 else { return 0 }
        return Double(done) / Double(target)
    }

    /// Which window we're in right now, based on the user's own chosen hours.
    var currentWindow: RitualWindow {
        let hour = Calendar.current.component(.hour, from: Date())
        let night = profile.nightHour
        let afternoon = profile.afternoonHour
        let morning = profile.morningHour

        if hour >= night || hour < morning { return .night }
        if hour >= afternoon { return .afternoon }
        return .morning
    }

    /// The next window that still has reps owing today.
    var suggestedWindow: RitualWindow {
        let current = currentWindow
        if !isComplete(current) { return current }
        return RitualWindow.allCases.first { !isComplete($0) } ?? current
    }

    // MARK: - Evidence

    var evidence: [EvidenceEntry] {
        state.evidence.sorted { $0.date > $1.date }
    }

    func addEvidence(_ entry: EvidenceEntry) {
        state.evidence.insert(entry, at: 0)
        scheduleSave()
    }

    func deleteEvidence(_ entry: EvidenceEntry) {
        state.evidence.removeAll { $0.id == entry.id }
        scheduleSave()
    }

    func evidenceLinked(to intentionID: UUID) -> [EvidenceEntry] {
        evidence.filter { $0.intentionID == intentionID }
    }

    // MARK: - Scripts

    var scripts: [ScriptEntry] {
        state.scripts.sorted { $0.createdAt > $1.createdAt }
    }

    func addScript(_ entry: ScriptEntry) {
        state.scripts.insert(entry, at: 0)
        scheduleSave()
    }

    func updateScript(_ entry: ScriptEntry) {
        guard let index = state.scripts.firstIndex(where: { $0.id == entry.id }) else { return }
        state.scripts[index] = entry
        scheduleSave()
    }

    func deleteScript(_ entry: ScriptEntry) {
        state.scripts.removeAll { $0.id == entry.id }
        scheduleSave()
    }

    func scriptsLinked(to intentionID: UUID) -> [ScriptEntry] {
        scripts.filter { $0.intentionID == intentionID }
    }

    // MARK: - The numbers that build trust

    var totalReps: Int {
        state.rituals.reduce(0) { $0 + $1.reps }
    }

    var receivedCount: Int { receivedIntentions.count }

    var evidenceCount: Int { state.evidence.count }

    /// Consecutive days ending today (or yesterday, if today hasn't happened yet)
    /// on which at least one ritual was completed.
    var streak: Int {
        let calendar = Calendar.current
        let days = Set(state.rituals.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        var cursor = today
        if !days.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    var daysSinceStart: Int {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: profile.startedAt),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        return max(0, days) + 1
    }

    /// A deliberately generous 0…1 read on how much the practice is being fed.
    /// It is encouragement, not a grade — it never goes down for a bad day alone.
    var alignment: Double {
        let streakPart = min(Double(streak) / 21.0, 1) * 0.45
        let repsPart = min(Double(totalReps) / 369.0, 1) * 0.35
        let evidencePart = min(Double(evidenceCount) / 30.0, 1) * 0.20
        return min(1, streakPart + repsPart + evidencePart)
    }

    var alignmentLabel: String {
        switch alignment {
        case ..<0.2:  return "Warming up"
        case ..<0.45: return "Finding the signal"
        case ..<0.7:  return "Tuned in"
        case ..<0.9:  return "Running clean"
        default:      return "Fully lit"
        }
    }

    // MARK: - Reset

    /// Replace everything with a restored backup.
    func restore(_ restored: ManifestState) {
        state = restored
        flush()
    }

    func eraseEverything() {
        state = ManifestState()
        flush()

        // Nothing should outlive the erase: not the queued reminders, not the
        // card on the lock screen, not what the widgets are holding.
        Whispers.cancelAll()
        LiveNote.end()
        publishSnapshot()
    }
}
