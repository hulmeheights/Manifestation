//
//  Moonlight.swift
//  Lumen
//
//  The design system: two faces of one app. Night is near-black with a real
//  starfield and a moon that carries the only light in the whole interface.
//  Day is near-white with the same type, the same layout and no glow at all.
//
//  The rule the whole thing hangs on: if it isn't the moon, it doesn't glow.
//  One warm accent, and it only ever means evidence.
//
//  This file is additive — the old Theme.swift still compiles and the current
//  screens still run. Views move across one at a time.
//

import SwiftUI

// MARK: - Which face

enum Appearance: String, Codable, CaseIterable, Identifiable, Hashable {
    /// Day for the morning three and the midday six, night for the nine.
    case auto
    case day
    case night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto:  return "Auto"
        case .day:   return "Day"
        case .night: return "Night"
        }
    }

    var blurb: String {
        switch self {
        case .auto:  return "Follows your three windows — light until the night nine."
        case .day:   return "Always light."
        case .night: return "Always dark."
        }
    }

    /// Resolve against the user's own window hours.
    func isNight(at date: Date = Date(), nightHour: Int = 21, morningHour: Int = 7) -> Bool {
        switch self {
        case .day:   return false
        case .night: return true
        case .auto:
            let hour = Calendar.current.component(.hour, from: date)
            if nightHour > morningHour {
                return hour >= nightHour || hour < morningHour
            }
            // Someone with unusual hours; fall back to something sane.
            return hour >= 21 || hour < 7
        }
    }
}

// MARK: - The two skins

struct Skin: Equatable {

    // Ground and ink
    let ground: Color
    let ink: Color
    let dim: Color
    /// Words not yet typed.
    let ghost: Color

    // Surfaces
    let hairline: Color
    let card: Color
    let track: Color
    let field: Color

    // The one accent — evidence, and nothing else
    let evidence: Color

    /// The wash behind words you've typed correctly.
    let highlight: Color

    // The moon
    let moonLit: Color
    let moonDark: Color
    let moonEdge: Color
    /// Nothing else in the app is allowed one of these.
    let moonGlow: Color
    let glowRadius: CGFloat

    let stars: Bool
    let isNight: Bool

    /// Still the sky: no glow behind the moon, no stars. Set from the user's
    /// own switch in You, and honoured by MoonDisc and NightStars.
    var calm: Bool = false

    /// A copy of this skin with the sky stilled (or not).
    func stilled(_ on: Bool) -> Skin {
        var copy = self
        copy.calm = on
        return copy
    }

    /// Button fill. Ink on paper, paper on ink — never a colour.
    var buttonFill: Color { ink }
    var buttonInk: Color { ground }

    // MARK: Night

    static let night = Skin(
        ground:    Color(hex2: 0x07080C),
        ink:       Color(hex2: 0xF5F7FA),
        dim:       Color(hex2: 0x7B808D),
        ghost:     Color(hex2: 0x2E323C),
        hairline:  Color.white.opacity(0.11),
        card:      Color.white.opacity(0.05),
        track:     Color.white.opacity(0.13),
        field:     Color.white.opacity(0.04),
        evidence:  Color(hex2: 0xE8B06A),
        highlight: Color(hex2: 0xFFEEC6).opacity(0.26),
        moonLit:   Color(hex2: 0xFFF6E0),
        moonDark:  Color(hex2: 0x11131A),
        moonEdge:  Color(hex2: 0xFFF6E0).opacity(0.30),
        moonGlow:  Color(hex2: 0xFFF0CD).opacity(0.45),
        glowRadius: 26,
        stars: true,
        isNight: true
    )

    // MARK: Day

    static let day = Skin(
        ground:    Color(hex2: 0xFBFBF9),
        ink:       Color(hex2: 0x15171A),
        dim:       Color(hex2: 0x84878E),
        ghost:     Color(hex2: 0xC7C9CD),
        hairline:  Color.black.opacity(0.10),
        card:      Color.white,
        track:     Color.black.opacity(0.09),
        field:     Color.white,
        evidence:  Color(hex2: 0x9A6B1F),
        highlight: Color(hex2: 0xF6E7C0),
        moonLit:   Color(hex2: 0xFBFBF9),
        moonDark:  Color(hex2: 0x15171A),
        moonEdge:  Color.black.opacity(0.32),
        moonGlow:  Color.clear,
        glowRadius: 0,
        stars: false,
        isNight: false
    )

    static func of(_ appearance: Appearance, nightHour: Int = 21, morningHour: Int = 7) -> Skin {
        appearance.isNight(nightHour: nightHour, morningHour: morningHour) ? .night : .day
    }
}

extension Color {
    /// Hex helper for the skin colours below.
    init(hex2: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex2 >> 16) & 0xFF) / 255,
            green: Double((hex2 >> 8) & 0xFF) / 255,
            blue: Double(hex2 & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Handing the skin down the view tree

private struct SkinKey: EnvironmentKey {
    static let defaultValue: Skin = .night
}

extension EnvironmentValues {
    var skin: Skin {
        get { self[SkinKey.self] }
        set { self[SkinKey.self] = newValue }
    }
}

extension View {
    func skin(_ skin: Skin) -> some View {
        environment(\.skin, skin)
            .preferredColorScheme(skin.isNight ? .dark : .light)
    }
}

// MARK: - Type
//
// One family at two jobs: tight and heavy for anything you read at a glance,
// monospaced for anything you count. If a licensed face is bundled later,
// only this section changes.

enum Ink {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .default)
    }
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let hero      = display(34)
    static let heading   = display(27)
    static let line      = title(21)
    static let read      = body(15)
    static let small     = body(13)
    static let label     = mono(11, weight: .medium)
    static let tiny      = mono(10, weight: .medium)
}

enum Space {
    static let gutter: CGFloat = 22
    static let gap: CGFloat = 14
    static let section: CGFloat = 30
    static let radius: CGFloat = 16
    static let pill: CGFloat = 999
}

// MARK: - The moon
//
// Drawn, not an image: a dark disc, a lit half, and an ellipse for the
// terminator whose width is the cosine of where we are in the lunation.

private struct HalfDisc: Shape {
    var rightSide: Bool

    func path(in rect: CGRect) -> Path {
        var disc = Path()
        disc.addEllipse(in: rect)

        var half = Path()
        half.addRect(
            rightSide
                ? CGRect(x: rect.midX, y: rect.minY, width: rect.width / 2, height: rect.height)
                : CGRect(x: rect.minX, y: rect.minY, width: rect.width / 2, height: rect.height)
        )
        return disc.intersection(half)
    }
}

struct MoonDisc: View {
    /// 0 at the new moon, 0.5 at the full moon, approaching 1 at the next new.
    var fraction: Double
    var size: CGFloat
    /// The glow is the app's one light source — off in daylight, off in a list.
    var glowing: Bool = true

    @Environment(\.skin) private var skin
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var waxing: Bool { fraction < 0.5 }
    private var gibbous: Bool { fraction > 0.25 && fraction < 0.75 }
    private var terminator: Double { abs(cos(2 * Double.pi * fraction)) }

    private var glowOn: Bool {
        glowing && skin.isNight && !reduceTransparency && !skin.calm
    }

    var body: some View {
        ZStack {
            Circle().fill(skin.moonDark)

            HalfDisc(rightSide: waxing)
                .fill(skin.moonLit)

            Ellipse()
                .fill(gibbous ? skin.moonLit : skin.moonDark)
                .frame(width: size * terminator, height: size)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle().strokeBorder(skin.moonEdge, lineWidth: 0.75)
        )
        .shadow(
            color: glowOn ? skin.moonGlow : .clear,
            radius: glowOn ? skin.glowRadius * (size / 120) : 0
        )
        .accessibilityHidden(true)
    }
}

// MARK: - Stars
//
// Fixed, not random per frame — the sky shouldn't shuffle when a view redraws.

private struct Seeded: RandomNumberGenerator {
    private var state: UInt64
    init(_ seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

struct NightStars: View {
    var count: Int = 90
    var seed: UInt64 = 20_260_915

    @Environment(\.skin) private var skin

    private struct Star {
        let x: Double, y: Double, r: Double, a: Double
    }

    private var stars: [Star] {
        var rng = Seeded(seed)
        return (0..<count).map { _ in
            Star(
                x: Double.random(in: 0...1, using: &rng),
                // Weighted toward the top of the screen, like a real sky above a horizon.
                y: pow(Double.random(in: 0...1, using: &rng), 1.7),
                r: Double.random(in: 0.5...1.4, using: &rng),
                a: Double.random(in: 0.18...0.75, using: &rng)
            )
        }
    }

    var body: some View {
        if skin.stars && !skin.calm {
            Canvas { context, size in
                for star in stars {
                    let rect = CGRect(
                        x: star.x * size.width,
                        y: star.y * size.height,
                        width: star.r * 2,
                        height: star.r * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.white.opacity(star.a))
                    )
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// The ground every screen sits on.
struct NightGround: View {
    @Environment(\.skin) private var skin

    var body: some View {
        ZStack {
            skin.ground
            NightStars()
        }
        .ignoresSafeArea()
    }
}

// MARK: - The typed line
//
// Words you've got right take a highlighter wash; the rest stay ghosted.
// This is the single most-looked-at thing in the app, so it lives here rather
// than inside the ritual screen.

struct TypedLine: View {
    let target: String
    let typed: String
    var font: Font = Ink.line
    var alignment: TextAlignment = .center

    @Environment(\.skin) private var skin

    var body: some View {
        Text(attributed)
            .font(font)
            .multilineTextAlignment(alignment)
            .lineSpacing(9)
            .animation(.easeOut(duration: 0.14), value: typed)
    }

    private var attributed: AttributedString {
        let words = target.split(separator: " ", omittingEmptySubsequences: false)
        let done = TypedLine.matchedCount(typed: typed, target: target)

        var out = AttributedString()
        for (index, word) in words.enumerated() {
            var piece = AttributedString(String(word))
            if index < done {
                piece.foregroundColor = skin.ink
                piece.backgroundColor = skin.highlight
            } else {
                piece.foregroundColor = skin.ghost
            }
            out.append(piece)
            if index < words.count - 1 {
                var space = AttributedString(" ")
                space.foregroundColor = skin.ghost
                out.append(space)
            }
        }
        return out
    }

    /// How many whole words of `target` have been typed correctly, in order.
    static func matchedCount(typed: String, target: String) -> Int {
        let normalise: (Substring) -> String = { piece in
            piece.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "'" }
        }
        let wanted = target.split(separator: " ").map(normalise)
        let got = typed.split(separator: " ").map(normalise)

        var matched = 0
        for (index, word) in got.enumerated() {
            guard index < wanted.count, word == wanted[index], !word.isEmpty else { break }
            matched += 1
        }
        return matched
    }

    static func isComplete(typed: String, target: String) -> Bool {
        let total = target.split(separator: " ").count
        return matchedCount(typed: typed, target: target) >= total && total > 0
    }
}

// MARK: - Buttons
//
// Ink on paper, paper on ink. No gradients anywhere in the app.

struct InkButtonStyle: ButtonStyle {
    @Environment(\.skin) private var skin
    var wide: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Ink.body(16, weight: .heavy))
            .foregroundStyle(skin.buttonInk)
            .frame(maxWidth: wide ? .infinity : nil)
            .padding(.vertical, 17)
            .padding(.horizontal, wide ? 16 : 26)
            .background(
                Capsule(style: .continuous).fill(skin.buttonFill)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    @Environment(\.skin) private var skin
    var wide: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Ink.body(16, weight: .bold))
            .foregroundStyle(skin.ink)
            .frame(maxWidth: wide ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, wide ? 16 : 26)
            .background(
                Capsule(style: .continuous).strokeBorder(skin.hairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InkButtonStyle {
    static var ink: InkButtonStyle { InkButtonStyle() }
}

extension ButtonStyle where Self == OutlineButtonStyle {
    static var outline: OutlineButtonStyle { OutlineButtonStyle() }
}

// MARK: - Small pieces

/// The uppercase mono label used above everything.
struct Eyebrow: View {
    let text: String
    var trailing: String? = nil

    @Environment(\.skin) private var skin

    var body: some View {
        HStack {
            Text(text.uppercased())
                .kerning(1.8)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing.uppercased())
                    .kerning(1.8)
            }
        }
        .font(Ink.label)
        .foregroundStyle(skin.dim)
    }
}

/// Reps, charge, cycle — one bar, never a colour.
struct Meter: View {
    var progress: Double
    var height: CGFloat = 4

    @Environment(\.skin) private var skin

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(skin.track)
                Capsule()
                    .fill(skin.ink)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
    }
}

/// The nine rep marks under the line.
struct RepMarks: View {
    var total: Int
    var done: Int

    @Environment(\.skin) private var skin

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(1, total), id: \.self) { index in
                Capsule()
                    .fill(index < done ? skin.ink : skin.track)
                    .frame(width: 13, height: 3)
            }
        }
        .animation(.easeOut(duration: 0.25), value: done)
        .accessibilityLabel("\(done) of \(total) written")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Night") {
    VStack(spacing: 34) {
        MoonDisc(fraction: 0.38, size: 140)
        TypedLine(
            target: "I have the studio on Mare Street and the rent is easy.",
            typed: "I have the studio on Mare"
        )
        .padding(.horizontal, 30)
        RepMarks(total: 9, done: 3)
        Meter(progress: 0.67).padding(.horizontal, 60)
        Button("Write it six more times") {}.buttonStyle(.ink)
            .padding(.horizontal, Space.gutter)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(NightGround())
    .skin(.night)
}

#Preview("Day") {
    VStack(spacing: 34) {
        MoonDisc(fraction: 0.38, size: 140)
        TypedLine(
            target: "I have the studio on Mare Street and the rent is easy.",
            typed: "I have the studio on Mare"
        )
        .padding(.horizontal, 30)
        RepMarks(total: 9, done: 3)
        Button("Write it three times") {}.buttonStyle(.ink)
            .padding(.horizontal, Space.gutter)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(NightGround())
    .skin(.day)
}
#endif
