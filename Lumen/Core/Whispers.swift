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

    /// How many reminders are actually queued with the system.
    static func pendingCount() async -> Int {
        let ids = Set(RitualWindow.allCases.map { prefix + $0.rawValue })
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.filter { ids.contains($0.identifier) }.count
    }

    /// Fires in five seconds so the user can see what one looks like.
    static func sendTest(line: String) {
        let content = UNMutableNotificationContent()
        content.title = "Night \u{2014} 9\u{00D7}"
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        content.body = trimmed.isEmpty
            ? "Nine times, the last thing you hand your sleeping mind."
            : trimmed
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: prefix + "test",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Moon nights worth turning up for — the new moon, the full moon, and
    /// anything bigger. Laid out a year ahead and refreshed whenever the app
    /// opens, so they survive without a server.
    static func scheduleMoonNights(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: (0..<40).map { "lumen.moon.\($0)" }
        )
        guard enabled else { return }

        let nights = MoonAlmanac.upcoming(months: 12).filter { $0.event.isMajor }
        for (index, night) in nights.prefix(20).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = night.title
            content.body = night.event.practice
            content.sound = .default

            var components = Calendar.current.dateComponents(
                [.year, .month, .day], from: night.date
            )
            components.hour = 19
            components.minute = 0

            center.add(
                UNNotificationRequest(
                    identifier: "lumen.moon.\(index)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
            )
        }
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
