//
//  LiveNote.swift
//  Lumen
//
//  Pushing the line live to the lock screen, and taking it down again.
//
//  Everything iOS actually allows, stated plainly, because the limits are
//  the design:
//
//   · Only the app can start a Live Activity, and only while it is open on
//     screen. Nothing can start one in the background.
//   · It survives the app being closed and the phone being locked. That is
//     the entire point.
//   · iOS ends it on its own after eight hours on screen, and removes it
//     from the lock screen twelve hours after that. We ask for the maximum
//     and re-arm it each time you write, so in practice it lives as long as
//     you keep the practice up.
//   · There can only be one of ours live at a time. Starting a second
//     replaces the first.
//   · If the user has Live Activities switched off for Moonwrit in
//     Settings, `areActivitiesEnabled` is false and we say so rather than
//     failing silently.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif


enum LiveNote {

    // MARK: - What the app is allowed to do right now

    /// False when the user has turned Live Activities off for Moonwrit, or
    /// the device doesn't do them at all.
    static var isAvailable: Bool {
        #if canImport(ActivityKit)
        return ActivityAuthorizationInfo().areActivitiesEnabled
        #else
        return false
        #endif
    }

    /// Is one of ours on the lock screen at this moment?
    static var isLive: Bool {
        #if canImport(ActivityKit)
        return !Activity<MoonwritAttributes>.activities.isEmpty
        #else
        return false
        #endif
    }

    // MARK: - Up

    /// Put the line on the lock screen and leave it there.
    ///
    /// Returns false when iOS refused — which is nearly always the user
    /// having them switched off in Settings.
    @discardableResult
    static func pin(line: String, state: MoonwritAttributes.ContentState, shape: MoonwritAttributes.Shape = .line) -> Bool {
        #if canImport(ActivityKit)
        guard isAvailable else { return false }

        // One at a time. A second card just makes the lock screen noisy.
        end()

        let attributes = MoonwritAttributes(shape: shape, line: line, startedAt: Date())
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            return true
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    // MARK: - Along

    /// Called after every rep, so the card counts up while you write.
    static func refresh(_ state: MoonwritAttributes.ContentState) {
        #if canImport(ActivityKit)
        let content = ActivityContent(state: state, staleDate: nil)
        for activity in Activity<MoonwritAttributes>.activities {
            Task { await activity.update(content) }
        }
        #endif
    }

    // MARK: - Down

    /// Take it off the lock screen now, not "eventually".
    static func end() {
        #if canImport(ActivityKit)
        for activity in Activity<MoonwritAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        #endif
    }
}
