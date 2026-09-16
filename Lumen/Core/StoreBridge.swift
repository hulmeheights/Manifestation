//
//  StoreBridge.swift
//  Lumen
//
//  What the store knows about the moon, the current chapter, and what the
//  widgets are allowed to see. Kept out of ManifestStore so the store stays
//  about persistence and nothing else.
//

import Foundation
import SwiftUI

extension ManifestStore {

    // MARK: - The moon

    var moon: MoonMoment { MoonPhase.moment() }

    /// The face to draw with right now.
    var skin: Skin { profile.skin }

    // MARK: - This chapter
    //
    // A chapter runs new moon to new moon. Intentions persist across as many
    // as they take — nothing resets, this is only a way of reading the work
    // back in months rather than days.

    var chapterStart: Date { moon.cycleStart }

    var repsThisChapter: Int {
        let start = chapterStart
        return state.rituals
            .filter { $0.date >= start }
            .reduce(0) { $0 + $1.reps }
    }

    var evidenceThisChapter: Int {
        let start = chapterStart
        return state.evidence.filter { $0.date >= start }.count
    }

    /// The last few chapters, most recent last, for the bars on the cycle screen.
    func recentChapters(_ count: Int = 3) -> [Chapter] {
        var result: [Chapter] = []
        for step in stride(from: count - 1, through: 0, by: -1) {
            guard let start = Calendar.current.date(
                byAdding: .day,
                value: -Int(MoonPhase.synodicMonth * Double(step)),
                to: chapterStart
            ) else { continue }
            let end = Calendar.current.date(
                byAdding: .day,
                value: Int(MoonPhase.synodicMonth.rounded()),
                to: start
            ) ?? Date()

            let reps = state.rituals
                .filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.reps }
            let signs = state.evidence.filter { $0.date >= start && $0.date < end }.count

            result.append(
                Chapter(
                    startedAt: start,
                    intentionID: focusIntention?.id,
                    reps: reps,
                    evidenceCount: signs
                )
            )
        }
        return result
    }

    // MARK: - The day

    var repsRemainingToday: Int {
        let target = RitualWindow.allCases.reduce(0) { $0 + $1.reps }
        return max(0, target - min(repsToday, target))
    }

    var dayTarget: Int {
        RitualWindow.allCases.reduce(0) { $0 + $1.reps }
    }

    // MARK: - Widgets

    /// Hand the widgets the small slice they're allowed to see.
    func publishSnapshot() {
        let focus = focusIntention
        SharedStore.write(
            SharedSnapshot(
                line: focus?.affirmation ?? "",
                repsToday: repsToday,
                repsTarget: dayTarget,
                repsHeld: focus?.reps ?? 0,
                tier: focus?.charge.title ?? "Seeded",
                evidenceThisChapter: evidenceThisChapter,
                windowTitle: currentWindow.title,
                updatedAt: Date()
            )
        )
    }

    /// Everything outside the app that mirrors what's inside it: the widgets,
    /// the fourteen days of queued reminders, and the lock screen card.
    ///
    /// One call, used everywhere the practice changes, so it is impossible to
    /// update one of the three and forget the others. Changing your line now
    /// changes what the notifications say, which it didn't before.
    func syncOutside() {
        publishSnapshot()
        Whispers.reschedule(
            profile: profile,
            line: focusIntention?.affirmation ?? ""
        )
        Whispers.scheduleMoonNights(
            enabled: profile.notificationsEnabled && profile.moonNightAlerts
        )
        refreshLive()
    }

    // MARK: - The lock screen card

    /// The moving half of the Live Activity, built from where the practice
    /// actually is right now.
    var liveState: MoonwritAttributes.ContentState {
        let moment = moon
        return MoonwritAttributes.ContentState(
            repsToday: repsToday,
            repsTarget: dayTarget,
            windowTitle: currentWindow.title,
            note: moment.phase.power.headline,
            moonFraction: moment.progress
        )
    }

    /// Push the line to the lock screen. Returns false when iOS said no.
    @discardableResult
    func pinLineLive() -> Bool {
        guard let line = focusIntention?.affirmation, !line.isEmpty else { return false }
        return LiveNote.pin(line: line, state: liveState)
    }

    /// Keep the card honest after a rep. Free when nothing is live.
    func refreshLive() {
        guard LiveNote.isLive else { return }
        LiveNote.refresh(liveState)
    }

    // MARK: - Paid

    /// True when everything is unlocked. Owner unlock is a local flag so your
    /// own devices never see a paywall; the subscription check goes here later.
    var isUnlocked: Bool { profile.ownerUnlocked }
}
