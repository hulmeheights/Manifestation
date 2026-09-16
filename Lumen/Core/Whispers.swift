//
//  Whispers.swift
//  Lumen
//
//  Local notifications carrying the user's own words back to them.
//
//  What iOS lets us control, and what it doesn't — worth being clear about,
//  because most of a notification's look is not ours:
//
//   · The small icon is ALWAYS the app icon of the installed build. There is
//     no API to change it. If it looks wrong, the build on the phone is old.
//   · The layout, the corner radius, the colours, the font — all system.
//     Nothing can style them, in any app.
//   · What we DO control: the title, the subtitle, the body, the sound, and
//     one attachment. The attachment is the only real visual lever, so every
//     notification here carries a drawn card — the same near-black ground,
//     glowing moon and cream type as the Live Activity, with your own line
//     on it. Pull the banner down and you see the whole card.
//   · A notification that fires while the app is open is thrown away by iOS
//     unless a delegate says otherwise. NotificationRelay is that delegate.
//   · Time Sensitive delivery (breaking through a Focus) needs a separate
//     entitlement from Apple, so these are ordinary notifications. Nothing
//     here pretends otherwise.
//
//  Nothing leaves the device.
//

import Foundation
import UserNotifications

enum Whispers {

    private static let prefix = "lumen.window."
    private static let moonPrefix = "lumen.moon."

    /// How many days of reminders we lay down at a time.
    ///
    /// They're scheduled individually rather than as three repeating alarms so
    /// each one can carry the correct moon for that night. iOS only holds 64
    /// pending notifications, so this is deliberately short of that, and the
    /// whole set is re-laid every time the app opens.
    private static let daysAhead = 14

    // MARK: - Permission

    static func authorisationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    static func requestAuthorisation() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    static func pendingCount() async -> Int {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.filter {
            $0.identifier.hasPrefix(prefix) || $0.identifier.hasPrefix(moonPrefix)
        }.count
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) || $0.hasPrefix(moonPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - The three a day

    /// Clears and re-lays the daily reminders. `line` is the user's own focus
    /// affirmation — it is the headline of every notification, never filler.
    static func reschedule(profile: Profile, line: String) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)

            guard profile.notificationsEnabled else { return }

            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let calendar = Calendar.current
            let now = Date()

            for day in 0..<daysAhead {
                guard let date = calendar.date(byAdding: .day, value: day, to: now) else { continue }

                for window in RitualWindow.allCases {
                    var components = calendar.dateComponents([.year, .month, .day], from: date)
                    components.hour = profile.hour(for: window)
                    components.minute = 0

                    guard
                        let fireDate = calendar.date(from: components),
                        fireDate > now
                    else { continue }

                    let moment = MoonPhase.moment(fireDate)

                    let content = UNMutableNotificationContent()
                    // The line is the headline. That's the entire point.
                    content.title = trimmed.isEmpty ? window.notificationBody : trimmed
                    content.subtitle = "\(window.title) · \(window.reps)× · \(moment.phase.title)"
                    content.body = moment.phase.power.headline
                    content.sound = .default
                    content.userInfo = ["window": window.rawValue]
                    content.threadIdentifier = "moonwrit.daily"

                    if let url = MoonImage.cardFile(
                        fraction: moment.progress,
                        line: content.title,
                        caption: "\(window.title) · \(window.reps)× · \(moment.phase.title)",
                        name: "w-\(day)-\(window.rawValue)"
                    ), let attachment = try? UNNotificationAttachment(
                        identifier: "card", url: url, options: nil
                    ) {
                        content.attachments = [attachment]
                    }

                    center.add(
                        UNNotificationRequest(
                            identifier: "\(prefix)\(day).\(window.rawValue)",
                            content: content,
                            trigger: UNCalendarNotificationTrigger(
                                dateMatching: calendar.dateComponents(
                                    [.year, .month, .day, .hour, .minute], from: fireDate
                                ),
                                repeats: false
                            )
                        )
                    )
                }
            }
        }
    }

    // MARK: - Nights worth turning up for

    /// New moons, full moons, supermoons, blue moons and eclipses — each with
    /// what that night is actually for.
    static func scheduleMoonNights(enabled: Bool) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(moonPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)

            guard enabled else { return }

            let calendar = Calendar.current
            let nights = MoonAlmanac.upcoming(months: 12)
                .filter { $0.event.isMajor || $0.event == .newMoon || $0.event == .fullMoon }
                .prefix(16)

            for (index, night) in nights.enumerated() {
                let moment = MoonPhase.moment(night.date)
                let strength = max(1, min(5, moment.phase.power.strength + night.event.amplifier))

                let content = UNMutableNotificationContent()
                content.title = night.title
                content.subtitle = strengthDescription(strength)
                content.body = night.event.amplified ?? moment.phase.power.headline
                content.sound = .default
                content.threadIdentifier = "moonwrit.moon"

                if let url = MoonImage.cardFile(
                    fraction: moment.progress,
                    line: night.title,
                    caption: strengthDescription(strength),
                    name: "m-\(index)"
                ), let attachment = try? UNNotificationAttachment(
                    identifier: "card", url: url, options: nil
                ) {
                    content.attachments = [attachment]
                }

                var components = calendar.dateComponents([.year, .month, .day], from: night.date)
                components.hour = 19
                components.minute = 0

                center.add(
                    UNNotificationRequest(
                        identifier: "\(moonPrefix)\(index)",
                        content: content,
                        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    )
                )
            }
        }
    }

    private static func strengthDescription(_ strength: Int) -> String {
        switch strength {
        case 5: return "Strongest night of the cycle"
        case 4: return "A strong night"
        case 3: return "A working night"
        default: return "A quiet night"
        }
    }

    // MARK: - Test

    /// What happened when you asked for one. The button reports this back
    /// rather than doing nothing and leaving you guessing.
    enum TestResult {
        case sent
        case needsPermission
        case blockedInSettings
        case failed(String)
    }

    /// Fires in five seconds so you can see exactly what one looks like —
    /// including while you're still looking at the app, because
    /// NotificationRelay tells iOS to show it anyway.
    ///
    /// Asks for permission first if it hasn't been asked, so the button works
    /// on a fresh install instead of silently failing.
    static func sendTest(line: String) async -> TestResult {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .denied:
            return .blockedInSettings
        case .notDetermined:
            let granted = await requestAuthorisation()
            guard granted else { return .needsPermission }
        default:
            break
        }

        let moment = MoonPhase.moment()
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let headline = trimmed.isEmpty
            ? "Nine times, the last thing you hand your sleeping mind."
            : trimmed
        let caption = "\(moment.phase.title) · Tonight"

        let content = UNMutableNotificationContent()
        content.title = headline
        content.subtitle = caption
        content.body = moment.phase.power.headline
        content.sound = .default
        content.threadIdentifier = "moonwrit.daily"

        if let url = MoonImage.cardFile(
            fraction: moment.progress,
            line: headline,
            caption: caption,
            name: "test-\(Int(Date().timeIntervalSince1970))"
        ), let attachment = try? UNNotificationAttachment(
            identifier: "card", url: url, options: nil
        ) {
            content.attachments = [attachment]
        }

        // A fresh identifier every time, so tapping twice gives you two
        // rather than the second quietly replacing the first.
        let request = UNNotificationRequest(
            identifier: prefix + "test." + UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )

        do {
            try await center.add(request)
            return .sent
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
