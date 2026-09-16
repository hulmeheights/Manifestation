//
//  LumenApp.swift
//  Lumen — shipping as Moonwrit
//
//  Write it down. Say it until you believe it. Go and be the person who has
//  it. Write down what shows up.
//

import SwiftUI

@main
struct LumenApp: App {

    @State private var store = ManifestStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Must happen before the app finishes launching, or notifications
        // that fire while the app is open are silently dropped by iOS.
        NotificationRelay.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                store.flush()
                store.syncOutside()
            }
        }
    }
}
