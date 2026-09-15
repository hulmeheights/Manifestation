//
//  YouScreen.swift
//  Lumen
//
//  Settings, including the appearance picker. Auto follows your own three
//  windows rather than a generic sunset — light until the night nine.
//

import SwiftUI

struct YouScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    @State private var confirmingErase = false

    var body: some View {
        @Bindable var bound = store

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("You")
                    .font(Ink.hero)
                    .foregroundStyle(skin.ink)
                    .padding(.top, 20)

                // MARK: Appearance

                Eyebrow(text: "Appearance")
                    .padding(.top, Space.section)

                appearancePicker
                    .padding(.top, 12)

                Text(store.profile.appearance.blurb)
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)

                // MARK: Windows

                Eyebrow(text: "The three windows")
                    .padding(.top, Space.section)

                VStack(spacing: 0) {
                    hourRow("Morning · three", value: $bound.profile.morningHour)
                    hourRow("Midday · six", value: $bound.profile.afternoonHour)
                    hourRow("Night · nine", value: $bound.profile.nightHour)
                }
                .padding(.top, 6)

                // MARK: Switches

                Eyebrow(text: "How it feels")
                    .padding(.top, Space.section)

                VStack(spacing: 0) {
                    toggleRow(
                        "Your line, sent back",
                        detail: "Three a day, at your hours. Nothing leaves this phone.",
                        isOn: $bound.profile.notificationsEnabled
                    )
                    toggleRow(
                        "Haptics",
                        detail: "A tap in the hand for every line finished.",
                        isOn: $bound.profile.hapticsEnabled
                    )
                    toggleRow(
                        "Calm motion",
                        detail: "Stills the moon's glow and everything else.",
                        isOn: $bound.profile.calmMotion
                    )
                    toggleRow(
                        "Your own voice",
                        detail: "Play your line back in your voice at the end of a visualisation.",
                        isOn: $bound.profile.playOwnVoice
                    )
                    toggleRow(
                        "Count up while visualising",
                        detail: "A clock, not a timer. Never rushes you on.",
                        isOn: $bound.profile.showVisualisationClock
                    )
                }
                .padding(.top, 6)

                // MARK: Yours

                Eyebrow(text: "Yours")
                    .padding(.top, Space.section)

                VStack(spacing: 0) {
                    toggleRow(
                        "Owner unlock",
                        detail: "Everything on, no subscription. For your own devices.",
                        isOn: $bound.profile.ownerUnlocked
                    )
                }
                .padding(.top, 6)

                // MARK: About

                VStack(alignment: .leading, spacing: 10) {
                    Text("Moonwrit")
                        .font(Ink.title(21))
                        .foregroundStyle(skin.ink)
                    Text("Write it down. Say it until you believe it. See it clearly. Then write down what shows up — that's the part everyone skips, and it's the one that builds the trust.")
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Practising since \(store.profile.startedAt.shortDay) · \(store.totalReps) reps · everything stays on this device")
                        .font(Ink.tiny)
                        .kerning(0.8)
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Space.section)

                Button("Erase everything") { confirmingErase = true }
                    .buttonStyle(.outline)
                    .padding(.top, 26)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .onChange(of: store.profile.notificationsEnabled) { _, on in
            Whispers.reschedule(
                profile: store.profile,
                line: store.focusIntention?.affirmation ?? ""
            )
            if on { Task { _ = await Whispers.requestAuthorisation() } }
        }
        .alert("Erase everything?", isPresented: $confirmingErase) {
            Button("Erase", role: .destructive) { store.eraseEverything() }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Every line, every rep and every piece of evidence. This can't be undone.")
        }
    }

    // MARK: Pieces

    private var appearancePicker: some View {
        @Bindable var bound = store

        return HStack(spacing: 6) {
            ForEach(Appearance.allCases) { option in
                Button {
                    bound.profile.appearance = option
                } label: {
                    Text(option.title)
                        .font(Ink.body(14, weight: .bold))
                        .foregroundStyle(store.profile.appearance == option ? skin.ground : skin.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(store.profile.appearance == option ? skin.ink : skin.card)
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                store.profile.appearance == option ? Color.clear : skin.hairline,
                                lineWidth: 1
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func hourRow(_ title: String, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
                .font(Ink.body(15, weight: .semibold))
                .foregroundStyle(skin.ink)
            Spacer()
            Text(String(format: "%02d:00", value.wrappedValue))
                .font(Ink.mono(14, weight: .semibold))
                .foregroundStyle(skin.ink)
                .monospacedDigit()

            Stepper("", value: value, in: 0...23)
                .labelsHidden()
                .fixedSize()
        }
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }

    private func toggleRow(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Ink.body(15, weight: .semibold))
                    .foregroundStyle(skin.ink)
                Text(detail)
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(skin.ink)
        }
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }
}
