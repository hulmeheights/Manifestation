//
//  AppIcons.swift
//  Lumen
//
//  Two home screen icons — the night moon and a light one — so the icon can
//  match the rest of the phone rather than always being a black square.
//

import UIKit

enum AppIconOption: String, CaseIterable, Identifiable {
    /// The primary icon in the asset catalog; setAlternateIconName(nil).
    case night
    case day

    var id: String { rawValue }

    var title: String {
        switch self {
        case .night: return "Night"
        case .day:   return "Light"
        }
    }

    var detail: String {
        switch self {
        case .night: return "Cream moon on near-black."
        case .day:   return "Ink moon on off-white."
        }
    }

    /// nil means the primary icon.
    var assetName: String? {
        switch self {
        case .night: return nil
        case .day:   return "AppIconDay"
        }
    }

    static var current: AppIconOption {
        guard let name = UIApplication.shared.alternateIconName else { return .night }
        return AppIconOption.allCases.first { $0.assetName == name } ?? .night
    }
}

@MainActor
enum AppIcons {

    static var supported: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    /// Swapping the icon makes iOS show a system alert. Nothing we can do
    /// about that, and it only appears on an actual change.
    static func set(_ option: AppIconOption) {
        guard supported else { return }
        let target = option.assetName
        guard UIApplication.shared.alternateIconName != target else { return }
        UIApplication.shared.setAlternateIconName(target) { _ in
            // A failure here means the icon isn't in the bundle. Nothing to
            // recover — the current icon simply stays.
        }
    }
}

// MARK: - Owner unlock
//
// A visible toggle is worthless: anyone who downloads the app can flip it.
// This is hidden behind a gesture and a passphrase instead.
//
// Be clear-eyed about what this is: obfuscation, not security. The passphrase
// is in the binary and a determined person could pull it out. It exists to
// stop ordinary users unlocking themselves, which is all it needs to do. The
// proper answer for the App Store is an offer code generated in App Store
// Connect and redeemed on your own Apple ID — that costs nothing, can't be
// reverse-engineered, and works on every device you sign into.

enum OwnerUnlock {
    /// Change this before you ship. Anything you'll remember and nobody guesses.
    private static let passphrase = "threesixnine"

    static func accepts(_ attempt: String) -> Bool {
        attempt
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            == passphrase
    }
}
