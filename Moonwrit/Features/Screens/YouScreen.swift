//
//  YouScreen.swift
//  Moonwrit
//
//  Settings, the guide, and the things that make the app yours.
//

import SwiftUI
import UIKit
import UserNotifications
import UniformTypeIdentifiers

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
    @State private var sending = false
    @State private var testMessage = ""
    @State private var diagnostics = ""
    @State private var exportItem: ShareItem?
    @State private var importing = false
    @State private var backupMessage = ""

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

                Text("Notifications always use the first icon, never this one — that's iOS, not a setting. If a notification still shows an older icon, the build on the phone is behind: run it again from Xcode and it catches up. Deleting the app clears it too, but that erases your practice with it, so rebuild first.")
                    .font(Ink.tiny)
                    .foregroundStyle(skin.ghost)
                    .padding(.top, 8)
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
                    toggleRow("Still the sky",
                              detail: "Turns off the glow behind the moon and the stars behind everything.",
                              isOn: $bound.profile.calmMotion)
                    toggleRow("Count up while visualising",
                              detail: "A clock, not a timer. It never rushes you on.",
                              isOn: $bound.profile.showVisualisationClock)
                }
                .padding(.top, 6)
    }

    @ViewBuilder
    private var footerBlock: some View {

                // MARK: Backup

                Eyebrow(text: "Your copy")
                    .padding(.top, Space.section)

                backupBlock
                    .padding(.top, 10)

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
        .sheet(item: $exportItem) { item in
            ShareSheet(items: [item.url])
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                if let restored = Backup.load(from: url) {
                    store.restore(restored)
                    store.syncOutside()
                    backupMessage = "Restored."
                } else {
                    backupMessage = "That file isn't a Moonwrit backup."
                }
            case .failure:
                backupMessage = "Couldn't open that file."
            }
        }
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
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Every line, every rep and every piece of evidence. This can't be undone.")
        }
    }

    // MARK: - Backup

    private var backupBlock: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Everything you've written lives in one file on this phone and nowhere else. That's the point — but it also means deleting the app takes it with it, and there's no server to get it back from.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)

            Button("Save a copy") {
                if let url = Backup.export(store.state) {
                    exportItem = ShareItem(url: url)
                    backupMessage = ""
                } else {
                    backupMessage = "Couldn't write the file."
                }
            }
            .buttonStyle(.outline)
            .frame(maxWidth: .infinity)

            Button("Restore from a copy") { importing = true }
                .buttonStyle(.plain)
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .frame(maxWidth: .infinity)

            if !backupMessage.isEmpty {
                Text(backupMessage)
                    .font(Ink.small)
                    .foregroundStyle(skin.evidence)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Put it in iCloud Drive, or email it to yourself. Restoring replaces everything currently in the app.")
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
    }

    // MARK: - Notifications

    private var statusLabel: String {
        switch notifyStatus {
        case .authorized, .provisional, .ephemeral: return "Allowed"
        case .denied:                                return "Blocked in iOS"
        default:                                     return "Not asked yet"
        }
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

        VStack(spacing: 0) {

            if notifyStatus == .denied {
                VStack(alignment: .leading, spacing: 12) {
                    Text("iOS is blocking them. Nothing the app can do from here — it has to be switched back on in iOS Settings, under Moonwrit → Notifications.")
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.outline)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            }

            // The switches are always here. Turning one on asks iOS for
            // permission if it hasn't been asked yet — you shouldn't have to
            // find a separate button first.
            toggleRow("Your line, three times a day",
                      detail: "At \(hour(store.profile.morningHour)), \(hour(store.profile.afternoonHour)) and \(hour(store.profile.nightHour)). Your own words, never filler.",
                      isOn: $bound.profile.notificationsEnabled)

            toggleRow("Moon nights",
                      detail: "New moons, full moons, supermoons and eclipses — with what each one is for.",
                      isOn: $bound.profile.moonNightAlerts)

            VStack(alignment: .leading, spacing: 10) {
                Text("See what one looks like")
                    .font(Ink.body(15, weight: .semibold))
                    .foregroundStyle(skin.ink)

                Text("It arrives in five seconds and shows even if you're still in the app. Every notification carries a drawn card — the moon as it is tonight, with your line on it.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .fixedSize(horizontal: false, vertical: true)

                Button(sending ? "On its way…" : "Send me one in 5 seconds") {
                    sending = true
                    testMessage = ""
                    Task {
                        let result = await Whispers.sendTest(
                            line: store.focusIntention?.affirmation ?? ""
                        )
                        switch result {
                        case .sent(let queued, let withCard):
                            if queued {
                                testMessage = withCard
                                    ? "Queued with iOS — it arrives in five seconds. Lock the phone now to see it on the lock screen."
                                    : "Queued with iOS — it arrives in five seconds, without the card. The card couldn't be drawn, which is worth telling me about."
                                Haptics.tick(store.profile.hapticsEnabled)
                            } else {
                                testMessage = "iOS took it but didn't queue it, which shouldn't happen. Send me the line below."
                            }
                        case .needsPermission:
                            testMessage = "You said no to notifications. Settings → Moonwrit → Notifications."
                        case .blockedInSettings:
                            testMessage = "iOS is blocking notifications for Moonwrit. Settings → Moonwrit → Notifications."
                        case .notDelivering:
                            testMessage = "Notifications are allowed, but banners, lock screen and notification centre are all switched off for Moonwrit, so there's nowhere to show it. Settings → Moonwrit → Notifications."
                        case .failed(let why):
                            testMessage = "iOS refused: \(why)"
                        }
                        sending = false
                        await refresh()
                    }
                }
                .buttonStyle(.outline)
                .frame(maxWidth: .infinity)
                .disabled(sending)

                if !testMessage.isEmpty {
                    Text(testMessage)
                        .font(Ink.small)
                        .foregroundStyle(skin.evidence)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Everything iOS will admit to about our own settings. If a
                // notification doesn't turn up, the reason is on this line.
                Text(diagnostics.isEmpty ? "Checking with iOS…" : diagnostics)
                    .font(Ink.tiny)
                    .foregroundStyle(skin.ghost)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
        }
        .onChange(of: store.profile.notificationsEnabled) { _, on in
            if on { askThenReschedule() } else { reschedule() }
        }
        .onChange(of: store.profile.moonNightAlerts) { _, on in
            if on { askThenReschedule() } else { reschedule() }
        }
        .onChange(of: store.profile.morningHour) { _, _ in reschedule() }
        .onChange(of: store.profile.afternoonHour) { _, _ in reschedule() }
        .onChange(of: store.profile.nightHour) { _, _ in reschedule() }
    }

    /// Flipping a switch on is the ask. If iOS says no, the switch goes back
    /// rather than sitting there on and doing nothing.
    private func askThenReschedule() {
        Task {
            let status = await Whispers.authorisationStatus()
            if status == .notDetermined {
                let granted = await Whispers.requestAuthorisation()
                if !granted {
                    store.profile.notificationsEnabled = false
                    store.profile.moonNightAlerts = false
                }
            }
            reschedule()
            await refresh()
        }
    }

    private func hour(_ value: Int) -> String { String(format: "%02d:00", value) }

    private func reschedule() {
        store.syncOutside()
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await refresh()
        }
    }

    private func refresh() async {
        notifyStatus = await Whispers.authorisationStatus()
        queued = await Whispers.pendingCount()
        diagnostics = await Whispers.diagnostics()
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
