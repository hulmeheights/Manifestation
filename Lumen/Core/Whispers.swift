//
//  Whispers.swift
//  Lumen
//
//  Three local notifications a day, at the hours the user picked, carrying
//  their own words back to them. Nothing leaves the device.
//

import Foundation
import UserNotifications

enum Whispers {

    private static let prefix = "lumen.window."

    static func authorisationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Returns true if we're allowed to post.
    @discardableResult
    static func requestAuthorisation() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    static func cancelAll() {
        let ids = RitualWindow.allCases.map { prefix + $0.rawValue }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Clears and re-lays the three daily reminders.
    /// `line` is the user's own focus affirmation, shown in the notification.
    static func reschedule(profile: Profile, line: String) {
        cancelAll()
        guard profile.notificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        for window in RitualWindow.allCases {
            let content = UNMutableNotificationContent()
            content.title = "\(window.title) — \(window.reps)×"
            content.body = trimmed.isEmpty ? window.notificationBody : trimmed
            content.sound = .default
            content.userInfo = ["window": window.rawValue]

            var components = DateComponents()
            components.hour = profile.hour(for: window)
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: prefix + window.rawValue,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
