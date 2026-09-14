//
//  SettingsView.swift
//  Lumen
//

import SwiftUI

struct SettingsView: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingErase = false

    var body: some View {
        NavigationStack {
            CosmicScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: Metric.sectionGap) {
                        nameSection
                        windowsSection
                        notificationsSection
                        feelSection
                        aboutSection
                        dangerSection
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Palette.gold)
                }
            }
            .confirmationDialog(
                "Erase everything?",
                isPresented: $confirmingErase,
                titleVisibility: .visible
            ) {
                Button("Erase it all", role: .destructive) {
                    store.eraseEverything()
                    Whispers.cancelAll()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Every intention, repetition, piece of evidence and scripted entry. There is no copy of this anywhere else.")
            }
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "You")
            WritingField(
                placeholder: "What should it call you?",
                text: profileBinding(\.name)
            )
        }
    }

    /// Read-modify-write of a single field on the profile struct.
    private func profileBinding<T>(_ keyPath: WritableKeyPath<Profile, T>) -> Binding<T> {
        Binding(
            get: { store.profile[keyPath: keyPath] },
            set: { newValue in
                var profile = store.profile
                profile[keyPath: keyPath] = newValue
                store.profile = profile
            }
        )
    }

    // MARK: - Windows

    private var windowsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "The three windows")

            GlassCard(padding: 6) {
                VStack(spacing: 0) {
                    ForEach(RitualWindow.allCases) { window in
                        hourRow(window)
                        if window != RitualWindow.allCases.last {
                            Divider().overlay(Palette.stroke).padding(.leading, 12)
                        }
                    }
                }
            }

            Text("Three in the morning, six in the middle of the day, nine at night. Move the hours to fit your life — the counts stay put.")
                .font(.tiny11)
                .foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func hourRow(_ window: RitualWindow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: window.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.gold)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(window.title)
                    .font(.body15)
                    .foregroundStyle(Palette.ink)
                Text("\(window.reps)×")
                    .font(.tiny11)
                    .foregroundStyle(Palette.faint)
            }

            Spacer()

            Picker("", selection: hourBinding(for: window)) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(Self.hourLabel(hour)).tag(hour)
                }
            }
            .pickerStyle(.menu)
            .tint(Palette.gold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func hourBinding(for window: RitualWindow) -> Binding<Int> {
        Binding(
            get: { store.profile.hour(for: window) },
            set: { newValue in
                var profile = store.profile
                switch window {
                case .morning:   profile.morningHour = newValue
                case .afternoon: profile.afternoonHour = newValue
                case .night:     profile.nightHour = newValue
                }
                store.profile = profile
                Whispers.reschedule(profile: profile, line: store.focusIntention?.affirmation ?? "")
            }
        )
    }

    private static func hourLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Whispers")

            GlassCard(padding: 16) {
                Toggle(isOn: notificationBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nudge me three times a day")
                            .font(.body15)
                            .foregroundStyle(Palette.ink)
                        Text("Your own line, sent back to you at your hours. Nothing leaves this phone.")
                            .font(.tiny11)
                            .foregroundStyle(Palette.faint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(Palette.gold)
            }
        }
    }

    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { store.profile.notificationsEnabled },
            set: { wanted in
                if wanted {
                    Task {
                        let granted = await Whispers.requestAuthorisation()
                        var profile = store.profile
                        profile.notificationsEnabled = granted
                        store.profile = profile
                        Whispers.reschedule(
                            profile: profile,
                            line: store.focusIntention?.affirmation ?? ""
                        )
                    }
                } else {
                    var profile = store.profile
                    profile.notificationsEnabled = false
                    store.profile = profile
                    Whispers.cancelAll()
                }
            }
        )
    }

    // MARK: - Feel

    private var feelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How it feels")

            GlassCard(padding: 16) {
                VStack(spacing: 14) {
                    Toggle(isOn: profileBinding(\.hapticsEnabled)) {
                        settingLabel("Haptics", "A tap in the hand for every line finished.")
                    }
                    .tint(Palette.gold)

                    Divider().overlay(Palette.stroke)

                    Toggle(isOn: profileBinding(\.calmMotion)) {
                        settingLabel("Calm motion", "Stills the stars and the aurora.")
                    }
                    .tint(Palette.gold)

                    Divider().overlay(Palette.stroke)

                    Toggle(isOn: profileBinding(\.tapToComplete)) {
                        settingLabel("Tap instead of typing", "Say each line out loud and tap to count it.")
                    }
                    .tint(Palette.gold)
                }
            }
        }
    }

    private func settingLabel(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body15)
                .foregroundStyle(Palette.ink)
            Text(detail)
                .font(.tiny11)
                .foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "About")

            GlassCard(padding: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Lumen")
                        .font(.titleSerif)
                        .foregroundStyle(Palette.ink)

                    Text("Write it down. Say it until you believe it. Write down what shows up. The third part is the one everyone skips, and it's the one that builds the trust.")
                        .font(.caption13)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider().overlay(Palette.stroke)

                    HStack {
                        Text("Practising since")
                            .font(.tiny11)
                            .foregroundStyle(Palette.faint)
                        Spacer()
                        Text(store.profile.startedAt.shortDay)
                            .font(.tiny11)
                            .foregroundStyle(Palette.muted)
                    }

                    HStack {
                        Text("Everything stays on this device")
                            .font(.tiny11)
                            .foregroundStyle(Palette.faint)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Palette.muted)
                    }
                }
            }
        }
    }

    // MARK: - Danger

    private var dangerSection: some View {
        Button("Erase everything") {
            confirmingErase = true
        }
        .buttonStyle(GhostButtonStyle(tint: Palette.rose, compact: true))
    }
}
