//
//  SharedSnapshot.swift
//  Lumen
//
//  The small slice of state the widgets are allowed to see. Written to the
//  App Group container whenever the store changes; read by the widget
//  extension, which never touches the real save file.
//
//  Keeping this separate means the widget can't accidentally hold the whole
//  practice in memory, and the save format stays free to change.
//

import Foundation
import WidgetKit

enum SharedStore {

    /// Change this to match the App Group you create in Xcode, in BOTH targets.
    /// Signing & Capabilities → + Capability → App Groups.
    static let appGroup = "group.com.hulmeheights.lumen"

    private static let filename = "widget-snapshot.json"

    private static var url: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(filename)
    }

    static func write(_ snapshot: SharedSnapshot) {
        guard let url else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(snapshot).write(to: url, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            // A widget that misses one update is not worth crashing the app for.
        }
    }

    /// Returns `.empty` rather than `.placeholder` when there is nothing to
    /// read. A widget showing an invented line would be worse than one
    /// showing none — and this is exactly what happens on a build without
    /// the App Group, so it has to be honest.
    static func read() -> SharedSnapshot {
        guard let url, let data = try? Data(contentsOf: url) else { return .empty }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(SharedSnapshot.self, from: data)) ?? .empty
    }
}

struct SharedSnapshot: Codable, Hashable {

    /// The line currently in the light.
    var line: String
    /// Reps written today, across all three windows.
    var repsToday: Int
    /// The day's target — 18 when all three windows are on.
    var repsTarget: Int
    /// Total reps on this intention, all time.
    var repsHeld: Int
    /// Charge tier name, for the small widget.
    var tier: String
    /// Evidence logged this chapter.
    var evidenceThisChapter: Int
    /// Which window is open right now, if any.
    var windowTitle: String
    /// Last written, so the widget can say "nothing yet today" honestly.
    var updatedAt: Date

    // The moon is recomputed inside the widget rather than stored, so the
    // display stays correct even if the app hasn't been opened for a week.

    static let placeholder = SharedSnapshot(
        line: "I have the studio on Mare Street and the rent is easy.",
        repsToday: 12,
        repsTarget: 18,
        repsHeld: 247,
        tier: "Magnetised",
        evidenceThisChapter: 5,
        windowTitle: "Night",
        updatedAt: Date()
    )

    static let empty = SharedSnapshot(
        line: "",
        repsToday: 0,
        repsTarget: 18,
        repsHeld: 0,
        tier: "Seeded",
        evidenceThisChapter: 0,
        windowTitle: "",
        updatedAt: Date()
    )

    var hasLine: Bool {
        !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var progress: Double {
        guard repsTarget > 0 else { return 0 }
        return min(1, Double(repsToday) / Double(repsTarget))
    }
}
