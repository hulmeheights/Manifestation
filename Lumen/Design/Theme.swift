//
//  Theme.swift
//  Lumen
//
//  Colour, type and spacing. The app is one mood — deep night, warm gold,
//  a lot of air — so it all lives in one file.
//

import SwiftUI

// MARK: - Colour

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Palette {
    // Ground
    static let void = Color(hex: 0x06050D)
    static let deep = Color(hex: 0x120B26)
    static let dusk = Color(hex: 0x1C1238)

    // Accents
    static let gold   = Color(hex: 0xEFC98A)
    static let amber  = Color(hex: 0xF0A868)
    static let rose   = Color(hex: 0xFF7FAF)
    static let lilac  = Color(hex: 0xB99BFF)
    static let violet = Color(hex: 0x7B5CFF)
    static let sky    = Color(hex: 0x6FC6FF)
    static let teal   = Color(hex: 0x3FE0C5)
    static let mint   = Color(hex: 0x8BE8A8)

    // Type
    static let ink   = Color(hex: 0xF7F3EA)
    static let muted = Color(hex: 0xA8A0C4)
    static let faint = Color(hex: 0x6B6389)

    // Surfaces
    static let card   = Color.white.opacity(0.055)
    static let raised = Color.white.opacity(0.09)
    static let stroke = Color.white.opacity(0.10)
}

// MARK: - Gradients

enum Grad {
    static let night = LinearGradient(
        colors: [Palette.void, Palette.deep, Palette.dusk],
        startPoint: .top,
        endPoint: .bottom
    )

    static let gold = LinearGradient(
        colors: [Color(hex: 0xFFE9C2), Palette.gold, Palette.amber],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let aurora = LinearGradient(
        colors: [Palette.lilac, Palette.rose, Palette.gold],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func halo(_ color: Color) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(0.55), color.opacity(0)],
            center: .center,
            startRadius: 1,
            endRadius: 160
        )
    }
}

// MARK: - Type
//
// Serif for anything the user is meant to *feel*; the system sans for
// anything they're meant to *operate*.

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static let heroSerif    = Font.system(size: 34, weight: .regular, design: .serif)
    static let titleSerif   = Font.system(size: 26, weight: .regular, design: .serif)
    static let quoteSerif   = Font.system(size: 20, weight: .regular, design: .serif)

    static let sectionLabel = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let cardTitle    = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body15       = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption13    = Font.system(size: 13, weight: .medium, design: .rounded)
    static let tiny11       = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let numeral      = Font.system(size: 28, weight: .semibold, design: .rounded)
}

// MARK: - Metrics

enum Metric {
    static let gutter: CGFloat = 20
    static let cardRadius: CGFloat = 22
    static let tileRadius: CGFloat = 18
    static let rowGap: CGFloat = 14
    static let sectionGap: CGFloat = 28
}

// MARK: - Formatting helpers

extension Date {
    var shortDay: String {
        formatted(.dateTime.day().month(.abbreviated))
    }

    var longDay: String {
        formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var timeOnly: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// "today" / "yesterday" / "3 Mar"
    var relativeDayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        if calendar.isDateInTomorrow(self) { return "Tomorrow" }
        return shortDay
    }
}

extension Int {
    var repsLabel: String { self == 1 ? "1 rep" : "\(self) reps" }
    var daysLabel: String { self == 1 ? "1 day" : "\(self) days" }
}
