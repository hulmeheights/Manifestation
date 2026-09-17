//
//  SessionEditor.swift
//  Moonwrit
//
//  Fixing up a saved visualisation, or taking one out. The same thing Proof
//  now does for evidence — nothing you write should be stuck as you first
//  typed it.
//

import SwiftUI

struct SessionEditor: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    let entry: ScriptEntry

    @State private var text = ""
    @State private var confirmingDelete = false

    var body: some View {
        ZStack {
            NightGround()

            VStack(alignment: .leading, spacing: 0) {

                Eyebrow(text: entry.title, trailing: entry.createdAt.relativeDayLabel)
                    .padding(.top, 22)

                Text("What you\nsaw.")
                    .font(Ink.hero)
                    .foregroundStyle(skin.ink)
                    .padding(.top, 16)

                TextField("", text: $text, axis: .vertical)
                    .lineLimit(4...12)
                    .font(Ink.body(16))
                    .foregroundStyle(skin.ink)
                    .tint(skin.evidence)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                            .fill(skin.field)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                            .strokeBorder(skin.hairline, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("You held it for \(entry.title) and wrote nothing. You can put it down now if you like.")
                                .font(Ink.body(16))
                                .foregroundStyle(skin.ghost)
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.top, 22)

                Text("The length is kept as it was \u{2014} that part isn't yours to edit.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .padding(.top, 14)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("Save it") { save() }
                    .buttonStyle(.ink)

                Button("Delete this session") { confirmingDelete = true }
                    .buttonStyle(.outline)
                    .padding(.top, 10)

                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 26)
            }
            .padding(.horizontal, Space.gutter)
        }
        .skin(store.skin)
        .alert("Delete this session?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) {
                store.deleteScript(entry)
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("The time you spent on it goes too.")
        }
        .onAppear { text = entry.body }
    }

    private func save() {
        var updated = entry
        updated.body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateScript(updated)
        Haptics.tick(store.profile.hapticsEnabled)
        dismiss()
    }
}
