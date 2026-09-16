//
//  LinesScreen.swift
//  Lumen
//
//  Everything you've written down. Unlimited lines, but only ever one in the
//  light — the one getting the 3-6-9, the notifications and the whole Write
//  screen. The rest are held: saved, editable, honestly showing zero.
//

import SwiftUI

struct LinesScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    @State private var writingNew = false
    @State private var editing: Intention?
    @State private var explainingFocus: Intention?
    @State private var markingReceived: Intention?

    var body: some View {
        NavigationStack {
            ZStack {
                NightGround()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        if let focus = store.focusIntention {
                            Eyebrow(text: "In the light", trailing: focus.charge.title)
                                .padding(.top, 8)

                            LineCard(intention: focus, inLight: true)
                                .padding(.top, 12)
                                .onTapGesture { editing = focus }

                            HStack(spacing: 8) {
                                Button("Edit it") { editing = focus }
                                    .buttonStyle(.outline)
                                Button("Received") { markingReceived = focus }
                                    .buttonStyle(.outline)
                            }
                            .padding(.top, 10)
                        }

                        let held = store.activeIntentions.filter { !$0.isFocus }
                        if !held.isEmpty {
                            Eyebrow(text: "Held", trailing: "\(held.count)")
                                .padding(.top, Space.section)

                            Text("Written down and waiting. They accumulate nothing until one is in the light — that's the honest thing to show.")
                                .font(Ink.small)
                                .foregroundStyle(skin.dim)
                                .padding(.top, 8)
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(spacing: 10) {
                                ForEach(held) { line in
                                    LineCard(intention: line, inLight: false)
                                        .onTapGesture { explainingFocus = line }
                                }
                            }
                            .padding(.top, 14)
                        }

                        let received = store.receivedIntentions
                        if !received.isEmpty {
                            Eyebrow(text: "Received", trailing: "\(received.count)")
                                .padding(.top, Space.section)

                            VStack(spacing: 10) {
                                ForEach(received) { line in
                                    LineCard(intention: line, inLight: false, received: true)
                                }
                            }
                            .padding(.top, 14)
                        }

                        Button("Write another line") { writingNew = true }
                            .buttonStyle(.ink)
                            .padding(.top, Space.section)
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Your lines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(skin.ink)
                }
            }
        }
        .skin(store.skin)
        .sheet(isPresented: $writingNew) { LineEditor(existing: nil) }
        .sheet(item: $editing) { line in LineEditor(existing: line) }
        .sheet(item: $explainingFocus) { line in FocusExplainer(candidate: line) }
        .alert("Mark as received?", isPresented: .constant(markingReceived != nil)) {
            Button("It arrived", role: .none) {
                if let line = markingReceived {
                    store.markReceived(line)
                    store.publishSnapshot()
                    Haptics.received(store.profile.hapticsEnabled)
                }
                markingReceived = nil
            }
            Button("Not yet", role: .cancel) { markingReceived = nil }
        } message: {
            Text("It moves to Received and keeps every rep. The next held line can step into the light.")
        }
    }
}

// MARK: - One line

private struct LineCard: View {
    let intention: Intention
    let inLight: Bool
    var received: Bool = false

    @Environment(\.skin) private var skin

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(intention.affirmation)
                .font(Ink.body(16, weight: .bold))
                .foregroundStyle(received ? skin.dim : skin.ink)
                .fixedSize(horizontal: false, vertical: true)

            if inLight {
                Meter(progress: intention.chargeProgress)
            }

            HStack(spacing: 8) {
                Text(intention.area.title.uppercased())
                    .font(Ink.tiny)
                    .kerning(1.2)
                Text("·")
                Text(received
                     ? "Received \(intention.receivedAt?.shortDay ?? "")"
                     : "\(intention.reps) reps")
                    .font(Ink.tiny)
                    .kerning(1.2)
                Spacer(minLength: 0)
                if inLight {
                    Text("IN THE LIGHT")
                        .font(Ink.tiny)
                        .kerning(1.3)
                        .foregroundStyle(skin.ground)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(skin.ink))
                } else if received {
                    Text("RECEIVED")
                        .font(Ink.tiny)
                        .kerning(1.3)
                        .foregroundStyle(skin.evidence)
                } else {
                    Text("HELD")
                        .font(Ink.tiny)
                        .kerning(1.3)
                        .foregroundStyle(skin.dim)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .overlay(Capsule().strokeBorder(skin.hairline, lineWidth: 1))
                }
            }
            .foregroundStyle(skin.dim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                .strokeBorder(inLight ? skin.ink.opacity(0.35) : skin.hairline, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Why it's waiting

private struct FocusExplainer: View {
    let candidate: Intention

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    private var nightsToNewMoon: Int { max(0, store.moon.nightsToNew) }

    var body: some View {
        ZStack {
            NightGround()

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: "Held")
                    .padding(.top, 26)

                Text("One at\na time.")
                    .font(Ink.hero)
                    .foregroundStyle(skin.ink)
                    .padding(.top, 16)

                Text("Eighteen reps on one line is a practice. Three each on six lines is a list. So everything you write is kept, but only one gets the work.")
                    .font(Ink.body(15))
                    .foregroundStyle(skin.dim)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)

                Text(candidate.affirmation)
                    .font(Ink.line)
                    .foregroundStyle(skin.ink)
                    .padding(.top, 26)
                    .fixedSize(horizontal: false, vertical: true)

                Text(nightsToNewMoon == 0
                     ? "The new moon is tonight — a clean place to swap."
                     : "The next new moon is \(nightsToNewMoon) \(nightsToNewMoon == 1 ? "night" : "nights") away. That's the tidy place to swap, but it's your practice.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .padding(.top, 14)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("Give this one the light") {
                    store.setFocus(candidate)
                    store.publishSnapshot()
                    Haptics.seal(store.profile.hapticsEnabled)
                    dismiss()
                }
                .buttonStyle(.ink)

                Button("Leave it held") { dismiss() }
                    .buttonStyle(.outline)
                    .padding(.top, 10)
                    .padding(.bottom, 26)
            }
            .padding(.horizontal, Space.gutter)
        }
        .skin(store.skin)
    }
}
