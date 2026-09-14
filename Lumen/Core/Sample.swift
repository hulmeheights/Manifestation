//
//  Sample.swift
//  Lumen
//
//  Fake practice data, for the Xcode canvas only. Never compiled into a
//  release build, and it writes to a scratch file so it can't touch the real
//  one.
//

#if DEBUG
import Foundation
import SwiftUI

enum Sample {

    /// Built once, so ids stay stable across previews that cross-reference them.
    static let state: ManifestState = makeState()

    private static func makeState() -> ManifestState {
        var state = ManifestState()

        var profile = Profile()
        profile.name = "Alex"
        profile.hasOnboarded = true
        profile.hapticsEnabled = true
        profile.startedAt = Date().addingTimeInterval(-60 * 60 * 24 * 47)
        state.profile = profile

        let money = Intention(
            affirmation: "Money finds me easily and often",
            area: .wealth,
            feeling: "Unbothered. Like the bill arriving is a non-event.",
            detail: "Enough that I stop doing the sums at 2am.",
            byDate: Date().addingTimeInterval(60 * 60 * 24 * 120),
            stage: .inMotion,
            reps: 147,
            isFocus: true,
            createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 40)
        )

        let home = Intention(
            affirmation: "I live in a home that feels like peace",
            area: .home,
            feeling: "Quiet. Warm. The door shuts and the world stops.",
            stage: .inMotion,
            reps: 42,
            createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 18)
        )

        let work = Intention(
            affirmation: "My work is seen and generously rewarded",
            area: .work,
            stage: .planted,
            reps: 9,
            createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 3)
        )

        let landed = Intention(
            affirmation: "The right people keep finding me",
            area: .love,
            stage: .received,
            reps: 212,
            createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 200),
            receivedAt: Date().addingTimeInterval(-60 * 60 * 24 * 11)
        )

        state.intentions = [money, home, work, landed]

        state.evidence = [
            EvidenceEntry(
                kind: .synchronicity,
                text: "Three separate people mentioned the same street to me today. I've never been.",
                intentionID: home.id,
                date: Date().addingTimeInterval(-60 * 60 * 5)
            ),
            EvidenceEntry(
                kind: .win,
                text: "Invoice paid two weeks early, without me chasing it once.",
                intentionID: money.id,
                date: Date().addingTimeInterval(-60 * 60 * 30)
            ),
            EvidenceEntry(
                kind: .sign,
                text: "11:11 twice. Then the song from that night came on in the shop.",
                date: Date().addingTimeInterval(-60 * 60 * 52)
            ),
            EvidenceEntry(
                kind: .received,
                text: "Met them at the thing I almost didn't go to.",
                intentionID: landed.id,
                date: Date().addingTimeInterval(-60 * 60 * 24 * 11)
            )
        ]

        state.scripts = [
            ScriptEntry(
                title: "The day the keys arrived",
                body: "It's raining and I don't care. The estate agent put the keys in my hand at 11 and I sat on the floor of the empty front room for an hour just listening to it. I rang Mum first. She cried before I did.",
                writtenFrom: Date().addingTimeInterval(60 * 60 * 24 * 95),
                intentionID: home.id,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 6)
            )
        ]

        var rituals: [RitualRecord] = []
        for dayOffset in 0..<12 {
            let day = Date().addingTimeInterval(-60 * 60 * 24 * Double(dayOffset))
            rituals.append(RitualRecord(date: day, window: .morning, intentionID: money.id, reps: 3))
            if dayOffset % 2 == 0 {
                rituals.append(RitualRecord(date: day, window: .night, intentionID: money.id, reps: 9))
            }
        }
        state.rituals = rituals

        return state
    }

    /// A store backed by a throwaway file so previews never touch real data.
    static func store() -> ManifestStore {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("lumen-preview-\(UUID().uuidString).json")
        return ManifestStore(fileURL: url, seed: state)
    }

    static func emptyStore() -> ManifestStore {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("lumen-preview-empty-\(UUID().uuidString).json")
        return ManifestStore(fileURL: url, seed: ManifestState())
    }

    static var focusIntention: Intention {
        state.intentions[0]
    }
}
#endif
