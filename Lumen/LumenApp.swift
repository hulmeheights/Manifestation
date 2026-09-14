//
//  LumenApp.swift
//  Lumen
//
//  Write it down. Say it until you believe it. Write down what shows up.
//

import SwiftUI
import UIKit

@main
struct LumenApp: App {

    @State private var store = ManifestStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Self.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(Palette.gold)
        }
        .onChange(of: scenePhase) { _, phase in
            // Don't wait out the debounce when the app leaves the screen.
            if phase != .active { store.flush() }
        }
    }

    /// UIKit bars don't pick up the SwiftUI palette on their own.
    private static func configureAppearance() {
        let ink = UIColor(Palette.ink)

        let tabBar = UITabBarAppearance()
        tabBar.configureWithTransparentBackground()
        tabBar.backgroundColor = UIColor(Palette.void).withAlphaComponent(0.72)
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar

        let navBar = UINavigationBarAppearance()
        navBar.configureWithTransparentBackground()
        navBar.titleTextAttributes = [.foregroundColor: ink]

        let largeSize: CGFloat = 32
        let base = UIFont.systemFont(ofSize: largeSize, weight: .regular)
        let serif = base.fontDescriptor.withDesign(.serif)
            .map { UIFont(descriptor: $0, size: largeSize) } ?? base
        navBar.largeTitleTextAttributes = [.foregroundColor: ink, .font: serif]

        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar
        UINavigationBar.appearance().compactAppearance = navBar
    }
}
