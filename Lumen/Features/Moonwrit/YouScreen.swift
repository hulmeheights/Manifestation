//
//  YouScreen.swift
//  Lumen
//
//  Settings, the guide, and the things that make the app yours.
//

import SwiftUI
import UIKit
import UserNotifications

struct YouScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin
    @Environment(\.scenePhase) private var scenePhase

    @State private var confirmingErase = false
    @State private var notifyStatus: UNAuthorizationStatus = .notDetermined
    @State private var queued = 0
    @State private var icon: AppIconOption = .night
    @State private var showingGuide = false
    @State private var showingUnlock = false
    @State private var unlockAttempt = ""
    @State private var unlockFailed = false
    @State private var live = false
    @State private var liveRefused = false

    // MARK: - Body
    //
    // Split into blocks because a SwiftUI VStack takes at most ten children.

    @ViewBuilder
    private var headBlock: some View {
                Text("You")
                    .font(Ink.hero)
                    .foregroundStyle(skin.ink)
                    .padding(.top, 20)

                // MARK: Guide

                Button {
                    showingGuide = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("How this works")
                                .font(Ink.body(16, weight: .bold))
                                .foregroundStyle(skin.ink)
                            Text("Why present tense, why typing, why the moon, and what the See screen is actually for.")
                                .font(Ink.small)
                                .foregroundStyle(skin.dim)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 10)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(skin.dim)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                            .strokeBorder(skin.hairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 22)
    }

    @ViewBuilder
    private var appearanceBlock: some View {
        @Bindable var bound = store

                // MARK: Appearance

                Eyebrow(text: "Appearance")
                    .padding(.top, Space.section)

                segmented(
                    options: Appearance.allCases,
                    selection: store.profile.appearance,
                    title: { $0.title }
                ) { option in
                    bound.profile.appearance = option
                }
                .padding(.top, 12)

                Text(store.profile.appearance.blurb)
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)

                // MARK: Home screen icon

                Eyebrow(text: "Home screen icon")
                    .padding(.top, Space.section)

                segmented(
                    options: AppIconOption.allCases,
                    selection: icon,
                    title: { $0.title }
                ) { option in
                    icon = option
                    AppIcons.set(option)
                }
                .padding(.top, 12)

                Text(icon.detail + " iOS shows its own alert when the icon changes — nothing we can turn off.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var alertsBlock: some View {

                // MARK: Notifications

                Eyebrow(text: "Notifications", trailing: statusLabel)
                    .padding(.top, Space.section)

                notificationsBlock
                    .padding(.top, 10)

                // MARK: The lock screen

                Eyebrow(text: "Lock screen", trailing: liveLabel)
                    .padding(.top, Space.section)

                lockScreenBlock
                    .padding(.top, 10)

                // MARK: Widgets

                Eyebrow(text: "Widgets")
                    .padding(.top, Space.section)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Home screen")
                        .font(Ink.body(15, weight: .semibold))
                        .foregroundStyle(skin.ink)

                    Text("Long-press an empty part of the home screen, tap + at the top, search Moonwrit. Small or medium. Long-press the widget afterwards and tap Edit Widget to choose the theme, what it leads with, and whether the moon shows.")
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle().fill(skin.hairline).frame(height: 1).padding(.vertical, 4)

                    Text("Lock screen")
                        .font(Ink.body(15, weight: .semibold))
                        .foregroundStyle(skin.ink)

                    Text("Long-press the lock screen, tap Customise, tap the lock screen itself, then the strip under the clock. Search Moonwrit. That one is permanent \u{2014} it never expires and you never have to re-add it.")
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                        .strokeBorder(skin.hairline, lineWidth: 1)
                )
                .padding(.top, 10)
    }

    @ViewBuilder
    private var windowsBlock: some View {
        @Bindable var bound = store

                // MARK: Windows

                Eyebrow(text: "The three windows")
                    .padding(.top, Space.section)

                VStack(spacing: 0) {
                    hourRow("Morning · three", value: $bound.profile.morningHour)
                    hourRow("Midday · six", value: $bound.profile.afternoonHour)
                    hourRow("Night · nine", value: $bound.profile.nightHour)
                }
                .padding(.top, 6)

                Text("Move the hours to fit your life — the counts stay put.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .padding(.top, 10)

                // MARK: Feel

                Eyebrow(text: "How it feels")
                    .padding(.top, Space.section)

                VStack(spacing: 0) {
                    toggleRow("Haptics",
                              detail: "A tap in the hand for every line finished.",
                              isOn: $bound.profile.hapticsEnabled)
                    toggleRow("Calm motion",
                              detail: "Stills the moon's glow and everything else.",
                              isOn: $bound.profile.calmMotion)
                    toggleRow("Your own voice",
                              detail: "Play your line back in your voice at the end of a visualisation.",
                              isOn: $bound.profile.playOwnVoice)
                    toggleRow("Count up while visualising",
                              detail: "A clock, not a timer. It never rushes you on.",
                              isOn: $bound.profile.showVisualisationClock)
                }
                .padding(.top, 6)
    }

    @ViewBuilder
    private var footerBlock: some View {

                // MARK: About

                about
                    .padding(.top, Space.section)

                Button("Erase everything") { confirmingErase = true }
                    .buttonStyle(.outline)
                    .padding(.top, 26)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headBlock
                appearanceBlock
                alertsBlock
                windowsBlock
                footerBlock
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
        .sheet(isPresented: $showingGuide) { GuideScreen() }
        .alert("Owner unlock", isPresented: $showingUnlock) {
            TextField("Passphrase", text: $unlockAttempt)
                .textInputAutocapitalization(.never)
            Button("Unlock") {
                if OwnerUnlock.accepts(unlockAttempt) {
                    store.profile.ownerUnlocked = true
                    Haptics.received(store.profile.hapticsEnabled)
                } else {
                    unlockFailed = true
                }
                unlockAttempt = ""
            }
            Button("Cancel", role: .cancel) { unlockAttempt = "" }
        } message: {
            Text("For your own devices. Everything on, no subscription.")
        }
        .alert("That's not it", isPresented: $unlockFailed) {
            Button("Fair enough", role: .cancel) {}
        }
        .alert("Erase everything?", isPresented: $confirmingErase) {
            Button("Erase", role: .destructive) {
                store.eraseEverything()
                store.publishSnapshot()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Every line, every rep and every piece of evidence. This can't be undone.")
        }
    }

    // MARK: - Notifications

    private var statusLabel: String {
        switch notifyStatus {
        case .authorized, .provisional, .ephemeral: return "Allowed"
        case .denied:                                return "Blocked in iOS"
        default:                                     return "Not asked yet"
        }
    }

    private var allowed: Bool {
        notifyStatus == .authorized || notifyStatus == .provisional || notifyStatus == .ephemeral
    }

    // MARK: - The lock screen card

    private var liveLabel: String {
        if !LiveNote.isAvailable { return "Blocked in iOS" }
        return live ? "Live" : "Off"
    }

    private var lockScreenBlock: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(live ? "Your line is on the lock screen" : "Put your line on the lock screen")
                .font(Ink.body(15, weight: .semibold))
                .foregroundStyle(skin.ink)

            Text("This is the one that sits on top of everything \u{2014} above the clock area, in the Dynamic Island, the first thing you read every time you pick the phone up. It stays until you take it down, and it counts your reps up as you write them.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            if store.focusIntention == nil {
                Text("Put a line in the light first \u{2014} Write \u{2192} All lines.")
                    .font(Ink.small)
                    .foregroundStyle(skin.evidence)
            } else if !LiveNote.isAvailable {
                Text("iOS has Live Activities switched off for Moonwrit. Settings \u{2192} Moonwrit \u{2192} Live Activities.")
                    .font(Ink.small)
                    .foregroundStyle(skin.evidence)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.outline)
            } else if live {
                Button("Take it down") {
                    LiveNote.end()
                    live = false
                }
                .buttonStyle(.outline)
                .frame(maxWidth: .infinity)
            } else {
                Button("Push it live") {
                    let ok = store.pinLineLive()
                    live = ok
                    liveRefused = !ok
                }
                .buttonStyle(.ink)
                .frame(maxWidth: .infinity)
            }

            if liveRefused {
                Text("iOS refused. That is nearly always Live Activities being off for Moonwrit in Settings.")
                    .font(Ink.small)
                    .foregroundStyle(skin.evidence)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("iOS takes it down on its own after about eight hours on screen. Writing a rep puts it back up.")
                .font(Ink.tiny)
                .foregroundStyle(skin.ghost)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                .strokeBorder(skin.hairline, lineWidth: 1)
        )
        .onAppear { live = LiveNote.isLive }
    }

    // MARK: - Notifications

    @ViewBuilder
    private var notificationsBlock: some View {
        @Bindable var bound = store

        if notifyStatus == .denied {
            VStack(alignment: .leading, spacing: 12) {
                Text("iOS is blocking them. Nothing the app can do from here — it has to be turned back on in iOS Settings.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open iOS Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.outline)
            }
        } else if !allowed {
            VStack(alignment: .leading, spacing: 12) {
                Text("Three a day at your hours, carrying your own line back to you — never generic filler. Everything is scheduled on this phone; nothing leaves it.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Turn notifications on") {
                    Task {
                        let granted = await Whispers.requestAuthorisation()
                        if granted {
                            store.profile.notificationsEnabled = true
                            reschedule()
                        }
                        await refresh()
                    }
                }
                .buttonStyle(.ink)
            }
        } else {
            VStack(spacing: 0) {
                toggleRow("Your line, three times a day",
                          detail: "At \(hour(store.profile.morningHour)), \(hour(store.profile.afternoonHour)) and \(hour(store.profile.nightHour)).",
                          isOn: $bound.profile.notificationsEnabled)

                toggleRow("Moon nights",
                          detail: "New moons, full moons, supermoons and eclipses — with what each one is for.",
                          isOn: $bound.profile.moonNightAlerts)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Try one")
                        .font(Ink.body(15, weight: .semibold))
                        .foregroundStyle(skin.ink)

                    Text(queued > 0
                         ? "\(queued) reminders are queued with iOS. Tap below and one arrives in five seconds so you can see exactly what it looks like — lock the phone straight after to see it properly on the lock screen."
                         : "Nothing is queued yet — turn the switch above on. Tap below and a sample arrives in five seconds.")
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Send me one in 5 seconds") {
                        Whispers.sendTest(line: store.focusIntention?.affirmation ?? "")
                        Haptics.tick(store.profile.hapticsEnabled)
                    }
                    .buttonStyle(.outline)
                }
                .padding(.vertical, 14)
            }
            .onChange(of: store.profile.notificationsEnabled) { _, _ in reschedule() }
            .onChange(of: store.profile.moonNightAlerts) { _, _ in reschedule() }
            .onChange(of: store.profile.morningHour) { _, _ in reschedule() }
            .onChange(of: store.profile.afternoonHour) { _, _ in reschedule() }
            .onChange(of: store.profile.nightHour) { _, _ in reschedule() }
        }
    }

    private func hour(_ value: Int) -> String { String(format: "%02d:00", value) }

    private func reschedule() {
        Whispers.reschedule(
            profile: store.profile,
            line: store.focusIntention?.affirmation ?? ""
        )
        Whispers.scheduleMoonNights(
            enabled: store.profile.notificationsEnabled && store.profile.moonNightAlerts
        )
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await refresh()
        }
    }

    private func refresh() async {
        notifyStatus = await Whispers.authorisationStatus()
        queued = await Whispers.pendingCount()
        icon = AppIconOption.current
    }

    // MARK: - About

    private var about: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Moonwrit")
                .font(Ink.title(21))
                .foregroundStyle(skin.ink)
                // Seven taps on the wordmark. Hidden on purpose — a visible
                // toggle would let anyone unlock themselves.
                .onTapGesture(count: 7) {
                    if store.profile.ownerUnlocked {
                        store.profile.ownerUnlocked = false
                    } else {
                        showingUnlock = true
                    }
                }

            Text("Write it down. Say it until you believe it. See it clearly. Then write down what shows up — that's the part everyone skips, and it's the one that builds the trust.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            Text("Practising since \(store.profile.startedAt.shortDay) · \(store.totalReps) reps · \(store.evidenceCount) logged · everything stays on this device")
                .font(Ink.tiny)
                .kerning(0.8)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            if store.profile.ownerUnlocked {
                Text("OWNER · EVERYTHING UNLOCKED")
                    .font(Ink.tiny)
                    .kerning(1.6)
                    .foregroundStyle(skin.evidence)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Reusable rows

    private func segmented<T: Identifiable & Equatable>(
        options: [T],
        selection: T,
        title: @escaping (T) -> String,
        pick: @escaping (T) -> Void
    ) -> some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                Button {
                    pick(option)
                } label: {
                    Text(title(option))
                        .font(Ink.body(14, weight: .bold))
                        .foregroundStyle(selection == option ? skin.ground : skin.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(selection == option ? skin.ink : skin.card))
                        .overlay(
                            Capsule().strokeBorder(
                                selection == option ? Color.clear : skin.hairline,
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

// MARK: - The guide

struct GuideScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    var body: some View {
        NavigationStack {
            ZStack {
                NightGround()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("How this\nworks.")
                            .font(Ink.hero)
                            .foregroundStyle(skin.ink)
                            .padding(.top, 8)

                        Text("Eleven questions, answered honestly. Come back whenever.")
                            .font(Ink.body(15))
                            .foregroundStyle(skin.dim)
                            .padding(.top, 12)

                        VStack(spacing: 12) {
                            ForEach(Library.guide) { card in
                                GuideCard(card: card)
                            }
                        }
                        .padding(.top, 24)
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(skin.ink)
                }
            }
        }
        .skin(store.skin)
    }
}

private struct GuideCard: View {
    let card: Library.Card
    @Environment(\.skin) private var skin
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.question)
                .font(Ink.title(17))
                .foregroundStyle(skin.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.answer)
                .font(Ink.body(15, weight: .semibold))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            if open {
                Text(card.detail)
                    .font(Ink.body(14))
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("More")
                    .font(Ink.tiny)
                    .kerning(1.4)
                    .foregroundStyle(skin.evidence)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                .strokeBorder(skin.hairline, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.22)) { open.toggle() }
        }
    }
}
