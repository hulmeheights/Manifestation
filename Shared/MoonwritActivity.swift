//
//  MoonwritActivity.swift
//  Shared between the app and the widget extension.
//
//  This is the Live Activity — the thing you push live and it sits on the
//  lock screen until you end it. It is NOT the same as a lock screen widget:
//
//    · A lock screen widget is a small permanent tile you add once, under
//      the clock. It is always there. It shows tonight's moon and your line.
//    · A Live Activity is a full-width card you start from inside the app.
//      It appears immediately, on top, on the lock screen and in the Dynamic
//      Island, and it stays there until you end it or iOS times it out.
//
//  Both exist in this app now. This file describes the second one.
//
//  Two shapes, chosen by the app:
//    · .line   — your line, held live, so it is the first thing you read
//                every time you pick the phone up. No timer, no countdown.
//    · .session — a writing session in progress: reps done out of the day's
//                target, ticking up as you type.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// The static half — set when you start it, never changes while it runs.
struct MoonwritAttributes: Codable, Hashable {

    enum Shape: String, Codable, Hashable {
        /// Hold the line on the lock screen.
        case line
        /// Track a writing session as it happens.
        case session
    }

    var shape: Shape = .line
    /// The line in the light at the moment it went live.
    var line: String = ""
    /// Drawn on the card so the moon is right without any shared data.
    var startedAt: Date = Date()

    /// The moving half — the app updates this and the card redraws.
    struct ContentState: Codable, Hashable {
        var repsToday: Int = 0
        var repsTarget: Int = 18
        /// "Morning", "Afternoon", "Night", or "" when no window is open.
        var windowTitle: String = ""
        /// One short line under the affirmation. Changes with the moon.
        var note: String = ""
        /// 0…1 through the lunation, so the card can draw the right moon.
        var moonFraction: Double = 0

        var progress: Double {
            guard repsTarget > 0 else { return 0 }
            return min(1, Double(repsToday) / Double(repsTarget))
        }
    }
}

#if canImport(ActivityKit)
extension MoonwritAttributes: ActivityAttributes {}
#endif
