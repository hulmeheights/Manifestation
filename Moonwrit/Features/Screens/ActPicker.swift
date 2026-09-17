//
//  ActPicker.swift
//  Moonwrit
//
//  Swapping today's act for another one of that trait's, and writing your own.
//
//  The app can only ever offer generic acts, because it doesn't know your
//  week. So rather than pretending otherwise, it hands the pen over: pick a
//  different one, or write the version that's actually true for you.
//

import SwiftUI

// MARK: - Pick a different one

struct ActPicker: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    let trait: Trait

    private var current: Act? {
        store.character.todaysActs().first { $0.trait.id == trait.id }?.act
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NightGround()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        Text(trait.title)
                            .font(Ink.hero)
                            .foregroundStyle(skin.ink)
                            .padding(.top, 10)

                        Text(trait.truth)
                            .font(Ink.body(15))
                            .foregroundStyle(skin.dim)
                            .padding(.top, 12)
                            .fixedSize(horizontal: false, vertical: true)

                        Eyebrow(text: "Pick one for today")
                            .padding(.top, Space.section)

                        Text("Every one of these costs you something. That isn't incidental \u{2014} an act with no cost teaches you nothing about yourself, so it casts no vote.")
                            .font(Ink.small)
                            .foregroundStyle(skin.dim)
                            .padding(.top, 8)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 0) {
                            ForEach(store.character.acts(for: trait)) { act in
                                row(act)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, 40)
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

    private func row(_ act: Act) -> some View {
        let picked = current?.id == act.id
        let mine = act.id.hasPrefix("own-")

        return Button {
            store.chooseAct(act, trait: trait)
            Haptics.tick(store.profile.hapticsEnabled)
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(picked ? skin.evidence : skin.hairline)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 5) {
                    if mine {
                        Text("YOURS")
                            .font(Ink.tiny)
                            .kerning(1.4)
                            .foregroundStyle(skin.evidence)
                    }

                    Text(act.text)
                        .font(Ink.body(16))
                        .foregroundStyle(skin.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if !act.cost.isEmpty {
                        Text("Costs you: \(act.cost)")
                            .font(Ink.small)
                            .foregroundStyle(skin.ghost)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 15)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(skin.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Write your own

struct OwnActEditor: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    let trait: Trait

    @State private var text = ""
    @State private var cost = ""

    private var canSave: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NightGround()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        Text("Your own\n\(trait.title.lowercased()) act.")
                            .font(Ink.hero)
                            .foregroundStyle(skin.ink)
                            .padding(.top, 10)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("The app can only offer general ones \u{2014} it doesn't know your week. Write the version that's actually true for you. Two rules, and they're the whole thing:")
                            .font(Ink.body(15))
                            .foregroundStyle(skin.dim)
                            .padding(.top, 12)
                            .fixedSize(horizontal: false, vertical: true)

                        rule("Doable before bed.", "If it needs a free Saturday, it's a plan, not an act.")
                        rule("It costs you something.", "Awkwardness, time, being wrong in front of someone. No cost, no vote.")

                        Eyebrow(text: "The act")
                            .padding(.top, Space.section)

                        field($text, placeholder: "Say the thing everyone is thinking, once, in the meeting.")
                            .padding(.top, 10)

                        Eyebrow(text: "What it costs you")
                            .padding(.top, 22)

                        field($cost, placeholder: "Being the one who said it.")
                            .padding(.top, 10)

                        Text("It'll be offered today, and then rotate in with \(trait.title.lowercased())'s others from tomorrow.")
                            .font(Ink.tiny)
                            .foregroundStyle(skin.ghost)
                            .padding(.top, 16)
                            .fixedSize(horizontal: false, vertical: true)

                        if !mine.isEmpty {
                            Eyebrow(text: "Ones you've written", trailing: "\(mine.count)")
                                .padding(.top, Space.section)

                            VStack(spacing: 0) {
                                ForEach(mine) { own in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text(own.text)
                                            .font(Ink.body(15))
                                            .foregroundStyle(skin.ink)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 8)
                                        Button {
                                            store.removeCustomAct(id: own.id)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(skin.dim)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 13)
                                    .overlay(alignment: .bottom) {
                                        Rectangle().fill(skin.hairline).frame(height: 1)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(skin.dim)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        store.addCustomAct(traitID: trait.id, text: text, cost: cost)
                        Haptics.tick(store.profile.hapticsEnabled)
                        dismiss()
                    }
                    .foregroundStyle(canSave ? skin.ink : skin.ghost)
                    .disabled(!canSave)
                }
            }
        }
        .skin(store.skin)
    }

    private var mine: [CustomAct] {
        store.character.customActs.filter { $0.traitID == trait.id }
    }

    private func rule(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Ink.body(15, weight: .semibold))
                .foregroundStyle(skin.ink)
            Text(body)
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }

    private func field(_ value: Binding<String>, placeholder: String) -> some View {
        TextField("", text: value, axis: .vertical)
            .font(Ink.body(16))
            .foregroundStyle(skin.ink)
            .tint(skin.evidence)
            .lineLimit(2...5)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.field)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                    .strokeBorder(skin.hairline, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if value.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(Ink.body(16))
                        .foregroundStyle(skin.ghost)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }
    }
}
