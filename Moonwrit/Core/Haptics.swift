//
//  Haptics.swift
//  Moonwrit
//
//  Physical feedback for the ritual. Every call is a no-op when the user has
//  turned haptics off in Settings.
//

import UIKit

@MainActor
enum Haptics {

    /// A completed repetition.
    static func rep(_ enabled: Bool) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// A light touch — selecting, toggling, tapping through.
    static func tick(_ enabled: Bool) {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// The end of a full 3, 6 or 9.
    static func seal(_ enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Something arrived — marking an intention received.
    static func received(_ enabled: Bool) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
}
