//
//  RootView.swift
//  Lumen
//
//  Onboarding until it's done, then the app. Nothing else lives here.
//

import SwiftUI

struct RootView: View {

    @Environment(ManifestStore.self) private var store

    var body: some View {
        Group {
            if store.profile.hasOnboarded {
                MoonwritRoot()
            } else {
                OpeningScreen()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: store.profile.hasOnboarded)
        .task { store.syncOutside() }
    }
}
