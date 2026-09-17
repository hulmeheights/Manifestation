//
//  LineEditor.swift
//  Moonwrit
//
//  Writing the line, with the rules checking themselves as you type. Most
//  people fail at this because their affirmation is bad — future tense, a
//  negative buried in it, or three goals wearing one coat. Catching that here
//  is worth more than anything else in the app.
//

import SwiftUI

struct LineEditor: View {

    /// nil when writing a new one.
    let existing: Intention?

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    @State private var line = ""
    @State private var area: LifeArea = .freedom
    @FocusState private var writing: Bool

    private var trimmed: String {
        line.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var checks: [LineCheck] { LineCheck.all(for: trimmed) }
    private var canSave: Bool { trimmed.split(separator: " ").count >= 3 }

    var body: some View {
        ZStack {
            NightGround()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: existing == nil ? "A new line" : "Your line")
                        .padding(.top, 22)

                    Text("One sentence,\nalready true.")
                        .font(Ink.hero)
                        .foregroundStyle(skin.ink)
                        .padding(.top, 16)

                    TextField("I have…", text: $line, axis: .vertical)
                        .lineLimit(2...5)
                        .focused($writing)
                        .font(Ink.line)
                        .foregroundStyle(skin.ink)
                        .tint(skin.ink)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                                .fill(skin.field)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                                .strokeBorder(skin.hairline, lineWidth: 1)
                        )
                        .padding(.top, 22)

                    VStack(spacing: 0) {
                        ForEach(checks) { check in
                            CheckRow(check: check)
                        }
                    }
                    .padding(.top, 18)

                    Eyebrow(text: "Part of life")
                        .padding(.top, Space.section)

                    areaPicker
                        .padding(.top, 12)

                    Text(Library.starters(for: area).first ?? "")
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .padding(.top, 12)
                        .onTapGesture { if trimmed.isEmpty { line = Library.starters(for: area).first ?? "" } }

                    Button(existing == nil ? "Put it in the light" : "Save it") { save() }
                        .buttonStyle(.ink)
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.45)
                        .padding(.top, Space.section)

                    Button("Cancel") { dismiss() }
                        .buttonStyle(.outline)
                        .padding(.top, 10)
                        .padding(.bottom, 26)
                }
                .padding(.horizontal, Space.gutter)
            }
            .scrollIndicators(.hidden)
        }
        .skin(store.skin)
        .onAppear {
            if let existing {
                line = existing.affirmation
                area = existing.area
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { writing = true }
        }
    }

    private var areaPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                ForEach(LifeArea.allCases) { option in
                    Button {
                        area = option
                    } label: {
                        Text(option.title)
                            .font(Ink.body(13, weight: .bold))
                            .foregroundStyle(area == option ? skin.ground : skin.ink)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(area == option ? skin.ink : skin.card))
                            .overlay(
                                Capsule().strokeBorder(
                                    area == option ? Color.clear : skin.hairline,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func save() {
        if var existing {
            existing.affirmation = trimmed
            existing.area = area
            store.update(existing)
        } else {
            var fresh = Intention(affirmation: trimmed, area: area)
            fresh.isFocus = store.focusIntention == nil
            store.add(fresh)
        }
        store.syncOutside()
        Haptics.seal(store.profile.hapticsEnabled)
        dismiss()
    }
}

// MARK: - The rules, checked live

struct LineCheck: Identifiable {
    let id: String
    let title: String
    let hint: String
    let passing: Bool

    static func all(for line: String) -> [LineCheck] {
        let lower = line.lowercased()
        let words = line.split(separator: " ").count
        let started = !line.isEmpty

        let future = ["i will", "will have", "going to", "i want", "i need", "i hope", "one day", "someday"]
        let negatives = ["not ", "n't", "never", "no more", "free of", "free from", "without", "debt", "stop "]

        return [
            LineCheck(
                id: "present",
                title: "Present tense",
                hint: "\u{201C}I have\u{201D}, not \u{201C}I will have\u{201D}. The future tense keeps it in the future.",
                passing: started && !future.contains { lower.contains($0) }
            ),
            LineCheck(
                id: "breath",
                title: "One breath long",
                hint: "You'll write this hundreds of times. Every extra word is friction.",
                passing: started && words >= 3 && words <= 13
            ),
            LineCheck(
                id: "negative",
                title: "Nothing to remove",
                hint: "\u{201C}I am debt free\u{201D} still says debt. Say what you have instead.",
                passing: started && !negatives.contains { lower.contains($0) }
            )
        ]
    }
}

private struct CheckRow: View {
    let check: LineCheck
    @Environment(\.skin) private var skin

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: check.passing ? "checkmark" : "circle.dotted")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(check.passing ? skin.ink : skin.dim)
                .frame(width: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(check.title)
                    .font(Ink.body(14, weight: .semibold))
                    .foregroundStyle(check.passing ? skin.ink : skin.dim)
                if !check.passing {
                    Text(check.hint)
                        .font(Ink.small)
                        .foregroundStyle(skin.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
        .animation(.easeOut(duration: 0.2), value: check.passing)
    }
}

// MARK: - Logging what came back

struct ProofComposer: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    /// Nil when writing a new one, set when correcting one you already filed.
    var existing: EvidenceEntry? = nil

    @State private var text = ""
    @State private var kind: EvidenceKind = .sign
    @State private var confirmingDelete = false
    @FocusState private var writing: Bool

    private var editing: Bool { existing != nil }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            NightGround()

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(
                    text: editing ? "Edit" : "New evidence",
                    trailing: (existing?.date ?? Date()).relativeDayLabel
                )
                .padding(.top, 22)

                Text(editing ? "Change what\nit says." : "What just\nhappened?")
                    .font(Ink.hero)
                    .foregroundStyle(skin.ink)
                    .padding(.top, 16)

                TextField(kind.prompt, text: $text, axis: .vertical)
                    .lineLimit(3...8)
                    .focused($writing)
                    .font(Ink.body(16))
                    .foregroundStyle(skin.ink)
                    .tint(skin.ink)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                            .fill(skin.field)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                            .strokeBorder(skin.hairline, lineWidth: 1)
                    )
                    .padding(.top, 22)

                kindPicker
                    .padding(.top, 16)

                Text("Small counts. The pile is the point, not the size of any one thing in it.")
                    .font(Ink.small)
                    .foregroundStyle(skin.dim)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button(editing ? "Save it" : "Add it") { save() }
                    .buttonStyle(.ink)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.45)

                if editing {
                    Button("Delete this one") { confirmingDelete = true }
                        .buttonStyle(.outline)
                        .padding(.top, 10)
                }

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
        .alert("Delete this?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) {
                if let existing { store.deleteEvidence(existing) }
                store.syncOutside()
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("It comes out of the pile for good.")
        }
        .onAppear {
            if let existing {
                text = existing.text
                kind = existing.kind
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { writing = true }
            }
        }
    }

    private var kindPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                ForEach(EvidenceKind.allCases) { option in
                    Button {
                        kind = option
                    } label: {
                        Text(option.title)
                            .font(Ink.body(13, weight: .bold))
                            .foregroundStyle(kind == option ? skin.ground : skin.ink)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(kind == option ? skin.ink : skin.card))
                            .overlay(
                                Capsule().strokeBorder(
                                    kind == option ? Color.clear : skin.hairline,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if var existing {
            existing.text = trimmed
            existing.kind = kind
            store.updateEvidence(existing)
            Haptics.tick(store.profile.hapticsEnabled)
        } else {
            store.addEvidence(
                EvidenceEntry(
                    kind: kind,
                    text: trimmed,
                    intentionID: store.focusIntention?.id
                )
            )
            Haptics.received(store.profile.hapticsEnabled)
        }

        store.syncOutside()
        dismiss()
    }
}
