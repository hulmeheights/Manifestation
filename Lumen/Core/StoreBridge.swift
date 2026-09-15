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

    // MARK: - Paid

    /// True when everything is unlocked. Owner unlock is a local flag so your
    /// own devices never see a paywall; the subscription check goes here later.
    var isUnlocked: Bool { profile.ownerUnlocked }
}
