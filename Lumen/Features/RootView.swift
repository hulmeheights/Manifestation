//
//  RootView.swift
//  Lumen
//

import SwiftUI

struct RootView: View {
    @Environment(ManifestStore.self) private var store

    var body: some View {
        Group {
            if store.profile.hasOnboarded {
                MainTabs()
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .task {
            // Keep the daily whispers carrying the current focus line.
            Whispers.reschedule(
                profile: store.profile,
                line: store.focusIntention?.affirmation ?? ""
            )
        }
    }
}

private struct MainTabs: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sparkles") }
                .tag(0)

            IntentionsView()
                .tabItem { Label("Intentions", systemImage: "star.fill") }
                .tag(1)

            EvidenceView()
                .tabItem { Label("Evidence", systemImage: "eye.fill") }
                .tag(2)

            ScriptingView()
                .tabItem { Label("Scripting", systemImage: "book.closed.fill") }
                .tag(3)
        }
        .tint(Palette.gold)
        .preferredColorScheme(.dark)
    }
}
