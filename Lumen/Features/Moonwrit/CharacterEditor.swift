//
//  CharacterEditor.swift
//  Lumen
//
//  Choosing who you're becoming. Three traits, no more — past three it stops
//  being a person and becomes a wish list, and wish lists don't get acted on.
//

import SwiftUI

struct CharacterEditor: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    @State private var who = ""
    @State private var chosen: [String] = []

    private let limit = 3

    var body: some View {
        NavigationStack {
            ZStack {
                NightGround()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        Text("Who are you\nbecoming?")
                            .font(Ink.hero)
                            .foregroundStyle(skin.ink)
                            .padding(.top, 10)

                        Text("In your own words. Not a job title — the version of you that already has the thing you're writing for. If a name helps, use one; nobody sees this.")
                            .font(Ink.body(15))
                            .foregroundStyle(skin.dim)
                            .padding(.top, 12)
                            .fixedSize(horizontal: false, vertical: true)

                        TextField("", text: $who, axis: .vertical)
                            .font(Ink.line)
                            .foregroundStyle(skin.ink)
                            .tint(skin.evidence)
                            .lineLimit(1...3)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                                    .fill(skin.field)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                                    .strokeBorder(skin.hairline, lineWidth: 1)
                            )
                            .padding(.top, 18)
                            .overlay(alignment: .topLeading) {
                                if who.isEmpty {
                                    Text("The version of me who runs the studio")
                                        .font(Ink.line)
                                        .foregroundStyle(skin.ghost)
                                        .padding(16)
                                        .padding(.top, 18)
                                        .allowsHitTesting(false)
                                }
                            }

                        Eyebrow(text: "What they're like", trailing: "\(chosen.count) of \(limit)")
                            .padding(.top, Space.section)

                        Text("Pick up to three. Each one becomes a handful of things you can actually do today — and the app will tell you what the fake version of it looks like, so you can catch yourself wearing it.")
                            .font(Ink.small)
                            .foregroundStyle(skin.dim)
                            .padding(.top, 10)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 0) {
                            ForEach(TraitLibrary.all) { trait in
                                row(trait)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("The character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(skin.dim)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundStyle(chosen.isEmpty ? skin.ghost : skin.ink)
                        .disabled(chosen.isEmpty)
                }
            }
        }
        .skin(store.skin)
        .onAppear {
            who = store.character.who
            chosen = store.character.traitIDs
        }
    }

    private func row(_ trait: Trait) -> some View {
        let picked = chosen.contains(trait.id)
        let full = chosen.count >= limit && !picked

        return Button {
            if picked {
                chosen.removeAll { $0 == trait.id }
            } else if !full {
                chosen.append(trait.id)
                Haptics.tick(store.profile.hapticsEnabled)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {

                Image(systemName: picked ? "checkmark.circle.fill" : trait.symbol)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(picked ? skin.evidence : skin.dim)
                    .frame(width: 24)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 5) {
                    Text(trait.title)
                        .font(Ink.body(17, weight: .semibold))
                        .foregroundStyle(full ? skin.ghost : skin.ink)

                    Text(trait.truth)
                        .font(Ink.small)
                        .foregroundStyle(full ? skin.ghost : skin.dim)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(skin.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(full)
    }

    private func save() {
        var sheet = store.character
        let trimmed = who.trimmingCharacters(in: .whitespacesAndNewlines)
        if sheet.traitIDs.isEmpty && !chosen.isEmpty {
            sheet.startedAt = Date()
        }
        sheet.who = trimmed
        sheet.traitIDs = chosen
        store.character = sheet
        dismiss()
    }
}

// MARK: - One trait, in full

struct TraitDetail: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    let trait: Trait

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

                        block("The impression", trait.impression)
                            .padding(.top, Space.section)

                        block("What it actually is", trait.truth)
                            .padding(.top, 18)

                        block("The tell", trait.tell)
                            .padding(.top, 18)

                        Eyebrow(text: "The acts", trailing: "\(store.character.votes(forTrait: trait.id)) cast")
                            .padding(.top, Space.section)

                        Text("Every one of these costs you something. That isn't incidental — an act with no cost casts no vote, because you learn nothing about yourself from doing the easy version.")
                            .font(Ink.small)
                            .foregroundStyle(skin.dim)
                            .padding(.top, 10)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(trait.acts) { act in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(act.text)
                                        .font(Ink.body(16))
                                        .foregroundStyle(skin.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("Costs you: \(act.cost)")
                                        .font(Ink.small)
                                        .foregroundStyle(skin.ghost)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 14)
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(skin.hairline).frame(height: 1)
                                }
                            }
                        }
                        .padding(.top, 8)
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

    private func block(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Ink.tiny)
                .kerning(1.4)
                .foregroundStyle(skin.dim)
            Text(text)
                .font(Ink.body(16))
                .foregroundStyle(skin.ink)
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
}
