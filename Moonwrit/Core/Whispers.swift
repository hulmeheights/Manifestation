//
//  Whispers.swift
//  Moonwrit
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

    private static let prefix = "moonwrit.window."
    private static let moonPrefix = "moonwrit.moon."

    /// How many days of reminders we lay down at a time.
    ///
    /// They're scheduled individually rather than as three repeating alarms so
    /// each one can carry the correct moon for that night. iOS only holds 64
    /// pending notifications, so this is deliberately short of that, and the
    /// whole set is re-laid every time the app opens.
    private static let daysAhead = 14

    // MARK: - Doing the work only when there is work

    /// Laying fourteen days of reminders means tearing down and re-adding
    /// nearly sixty requests. That used to happen every single time the app
    /// went to the background, which is expensive for no reason: the schedule
    /// only changes when your line, your hours or the switches change, or when
    /// the day rolls over. This remembers the last shape and skips the work.
    private static func unchanged(_ fingerprint: String, key: String) -> Bool {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: key) == fingerprint { return true }
        defaults.set(fingerprint, forKey: key)
        return false
    }

    /// Forget the fingerprints, so the next call really does re-lay.
    private static func forgetFingerprints() {
        UserDefaults.standard.removeObject(forKey: "moonwrit.schedule.daily")
        UserDefaults.standard.removeObject(forKey: "moonwrit.schedule.moon")
    }

    private static var today: String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

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
        forgetFingerprints()
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
        let fingerprint = [
            today,
            String(profile.notificationsEnabled),
            String(profile.morningHour),
            String(profile.afternoonHour),
            String(profile.nightHour),
            line
        ].joined(separator: "|")

        guard !unchanged(fingerprint, key: "moonwrit.schedule.daily") else { return }

        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)

            guard profile.notificationsEnabled else { return }

            MoonImage.sweepOldCards()

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

                    // One card per DAY, shared by that day's three windows —
                    // the moon is the same all day and the window detail is
                    // already in the subtitle. Fourteen images instead of
                    // forty-two, and cached, so re-laying costs nothing.
                    if let url = MoonImage.cardFile(
                        fraction: moment.progress,
                        line: trimmed.isEmpty ? window.notificationBody : trimmed,
                        caption: moment.phase.title,
                        name: cardName(for: fireDate, line: trimmed)
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
        let fingerprint = "\(today)|\(enabled)"
        guard !unchanged(fingerprint, key: "moonwrit.schedule.moon") else { return }

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

    /// Same card for every notification on a given day and line. Changing the
    /// line changes the name, so the cards are redrawn rather than going
    /// stale — which is the whole reason the line is in the name.
    private static func cardName(for date: Date, line: String) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let day = String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        return "d-\(day)-\(stableHash(line))"
    }

    /// Swift's own `hashValue` is seeded per launch, so it would give a
    /// different answer every time the app starts and the cache would never
    /// hit. FNV-1a is stable across launches, which is all this needs.
    private static func stableHash(_ text: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 36)
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
        case sent(queued: Bool, withCard: Bool)
        case needsPermission
        case blockedInSettings
        case notDelivering
        case failed(String)
    }

    /// Everything iOS will tell us about our own notification settings, in one
    /// line, so a failure can be read off the screen instead of guessed at.
    static func diagnostics() async -> String {
        let s = await UNUserNotificationCenter.current().notificationSettings()

        func word(_ setting: UNNotificationSetting) -> String {
            switch setting {
            case .enabled:       return "on"
            case .disabled:      return "off"
            case .notSupported:  return "n/a"
            @unknown default:    return "?"
            }
        }

        let auth: String
        switch s.authorizationStatus {
        case .authorized:    auth = "allowed"
        case .provisional:   auth = "quiet only"
        case .denied:        auth = "blocked"
        case .notDetermined: auth = "not asked"
        case .ephemeral:     auth = "temporary"
        @unknown default:    auth = "unknown"
        }

        let pending = await pendingCount()
        return "iOS says: \(auth) · banners \(word(s.alertSetting)) · lock screen \(word(s.lockScreenSetting)) · sound \(word(s.soundSetting)) · \(pending) queued"
    }

    /// Fires in five seconds so you can see exactly what one looks like —
    /// including while you're still looking at the app, because
    /// NotificationRelay tells iOS to show it anyway.
    ///
    /// Asks for permission first if it hasn't been asked, so the button works
    /// on a fresh install instead of silently failing. Then it checks the
    /// request actually landed in iOS's queue, because `add` succeeding is not
    /// the same thing as iOS agreeing to deliver it.
    @MainActor
    static func sendTest(line: String) async -> TestResult {
        let center = UNUserNotificationCenter.current()
        var settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .denied:
            return .blockedInSettings
        case .notDetermined:
            let granted = await requestAuthorisation()
            guard granted else { return .needsPermission }
            settings = await center.notificationSettings()
        default:
            break
        }

        // Allowed, but every way of showing one is switched off. Sending it
        // would be pointless and look like a bug.
        if settings.alertSetting != .enabled
            && settings.lockScreenSetting != .enabled
            && settings.notificationCenterSetting != .enabled {
            return .notDelivering
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

        // The card is drawn here on the main actor. A bad attachment makes iOS
        // drop the whole notification at delivery time, so if it can't be
        // built we send without it rather than send something iOS will bin.
        var withCard = false
        if let url = MoonImage.cardFile(
            fraction: moment.progress,
            line: headline,
            caption: caption,
            name: "test-\(UUID().uuidString)"
        ), let attachment = try? UNNotificationAttachment(
            identifier: "card", url: url, options: nil
        ) {
            content.attachments = [attachment]
            withCard = true
        }

        let id = prefix + "test." + UUID().uuidString
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )

        do {
            try await center.add(request)
        } catch {
            return .failed(error.localizedDescription)
        }

        // Did it actually queue? `add` returning without throwing is not proof.
        let queued = await center.pendingNotificationRequests()
            .contains { $0.identifier == id }

        return .sent(queued: queued, withCard: withCard)
    }
}
