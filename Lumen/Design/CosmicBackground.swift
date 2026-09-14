//
//  CosmicBackground.swift
//  Lumen
//
//  The sky the whole app sits on: a night gradient, a few slow aurora blooms
//  and a field of stars that breathe. Respects the "calm motion" setting and
//  the system Reduce Motion switch — both freeze it to a still image.
//

import SwiftUI

// MARK: - Stars

private struct Star {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let alpha: Double
    let speed: Double
    let phase: Double

    static func random() -> Star {
        Star(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            radius: CGFloat.random(in: 0.5...1.7),
            alpha: Double.random(in: 0.25...0.9),
            speed: Double.random(in: 0.35...1.1),
            phase: Double.random(in: 0...(.pi * 2))
        )
    }
}

struct Starfield: View {
    var count: Int = 90
    var animated: Bool = true

    @State private var stars: [Star] = []

    var body: some View {
        Group {
            if animated {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
                    canvas(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                canvas(at: 0)
            }
        }
        .onAppear {
            if stars.isEmpty {
                stars = (0..<count).map { _ in Star.random() }
            }
        }
        .allowsHitTesting(false)
    }

    private func canvas(at time: TimeInterval) -> some View {
        Canvas { context, size in
            for star in stars {
                let twinkle = 0.45 + 0.55 * (sin(time * star.speed + star.phase) * 0.5 + 0.5)
                let radius = star.radius
                let rect = CGRect(
                    x: star.x * size.width - radius,
                    y: star.y * size.height - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.white.opacity(star.alpha * twinkle))
                )
            }
        }
    }
}

// MARK: - Aurora

private struct AuroraBloom: View {
    let color: Color
    let size: CGFloat
    let start: CGPoint
    let drift: CGSize
    let duration: Double
    let animated: Bool

    @State private var moved = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.42), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .offset(
                x: start.x + (moved ? drift.width : 0),
                y: start.y + (moved ? drift.height : 0)
            )
            .blur(radius: 36)
            .onAppear {
                guard animated else { return }
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    moved = true
                }
            }
    }
}

// MARK: - The whole sky

struct CosmicBackground: View {
    var intensity: Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(ManifestStore.self) private var store

    private var animated: Bool {
        !systemReduceMotion && !store.profile.calmMotion
    }

    var body: some View {
        ZStack {
            Grad.night
                .ignoresSafeArea()

            AuroraBloom(
                color: Palette.violet,
                size: 420,
                start: CGPoint(x: -110, y: -230),
                drift: CGSize(width: 60, height: 70),
                duration: 17,
                animated: animated
            )

            AuroraBloom(
                color: Palette.rose,
                size: 360,
                start: CGPoint(x: 140, y: 60),
                drift: CGSize(width: -70, height: -50),
                duration: 21,
                animated: animated
            )

            AuroraBloom(
                color: Palette.teal,
                size: 300,
                start: CGPoint(x: -60, y: 320),
                drift: CGSize(width: 80, height: -60),
                duration: 25,
                animated: animated
            )

            Starfield(count: 90, animated: animated)
                .ignoresSafeArea()

            // Settles everything down so text stays readable over the blooms.
            LinearGradient(
                colors: [Color.black.opacity(0.10), Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .opacity(intensity)
        .ignoresSafeArea()
    }
}

/// Applies the sky behind any screen, under a dark scheme.
struct CosmicScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            CosmicBackground()
            content
        }
        .preferredColorScheme(.dark)
        .tint(Palette.gold)
    }
}
