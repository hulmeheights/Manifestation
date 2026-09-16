//
//  NotificationRelay.swift
//  Lumen
//
//  Without this object, a notification that fires while the app is open on
//  screen is swallowed by iOS and never shown. That is the default behaviour
//  for every app, and it is why "send me one in 5 seconds" looked broken —
//  it was arriving, and iOS was silently discarding it because you were
//  looking at the app at the time.
//
//  This delegate says: show it anyway. It has to be installed before the app
//  finishes launching, so it is set in LumenApp's init.
//

import Foundation
import UserNotifications

final class NotificationRelay: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationRelay()

    /// Call once, as early as possible.
    static func install() {
        UNUserNotificationCenter.current().delegate = shared
    }

    // Shown even when the app is frontmost.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    // Tapping one just opens the app. There is no deep link yet, and a
    // notification that dumps you somewhere unexpected is worse than one
    // that doesn't.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Intentionally empty.
    }
}
