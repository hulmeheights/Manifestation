//
//  ScriptEditorView.swift
//  Lumen
//

import SwiftUI

struct ScriptEditorView: View {

    let existing: ScriptEntry?

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var writtenFrom: Date = Date().addingTimeInterval(60 * 60 * 24 * 30)
    @State private var linkedID: UUID?
    @State private var prompt: String = Library.scriptPrompts.randomElement() ?? ""
    @State private var loaded = false

    private var canSave: Bool {
        bodyText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5
    }

    var body: some View {
        NavigationStack {
            CosmicScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: Metric.sectionGap) {
                        dateField
                        promptCard
                        titleField
                        bodyField
                        linkPicker
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(existing == nil ? "New entry" : "Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .foregroundStyle(canSave ? Palette.gold : Palette.faint)
                        .disabled(!canSave)
                }
            }
        }
        .onAppear(perform: loadOnce)
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Writing from")

            GlassCard(padding: 14) {
                DatePicker(
                    "The day it happened",
                    selection: $writtenFrom,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .font(.body15)
                .foregroundStyle(Palette.ink)
                .tint(Palette.gold)
            }
        }
    }

    private var promptCard: some View {
        Button {
            Haptics.tick(store.profile.hapticsEnabled)
            var next = Library.scriptPrompts.randomElement() ?? prompt
            if Library.scriptPrompts.count > 1 {
                while next == prompt {
                    next = Library.scriptPrompts.randomElement() ?? prompt
                }
            }
            withAnimation(.easeInOut(duration: 0.2)) { prompt = next }
        } label: {
            GlassCard(padding: 16) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.gold)

                    Text(prompt)
                        .font(.quoteSerif)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.faint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Call it something")
            WritingField(placeholder: "The day the keys arrived", text: $title)
        }
    }

    private var bodyField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How it went")

            TextField("It's done. Tell me everything…", text: $bodyText, axis: .vertical)
                .lineLimit(8...30)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(Palette.ink)
                .tint(Palette.gold)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Palette.stroke, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var linkPicker: some View {
        let options = store.activeIntentions
        if !options.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "About which intention")

                FlowLayout(spacing: 8, lineSpacing: 8, alignment: .leading) {
                    ForEach(options) { intention in
                        SelectableChip(
                            text: intention.affirmation,
                            symbol: intention.area.symbol,
                            tint: intention.area.tint,
                            isSelected: linkedID == intention.id
                        ) {
                            Haptics.tick(store.profile.hapticsEnabled)
                            linkedID = (linkedID == intention.id) ? nil : intention.id
                        }
                    }
                }
            }
        }
    }

    private func loadOnce() {
        guard !loaded else { return }
        loaded = true
        guard let existing else { return }
        title = existing.title
        bodyText = existing.body
        writtenFrom = existing.writtenFrom
        linkedID = existing.intentionID
    }

    private func save() {
        guard canSave else { return }
        Haptics.tick(store.profile.hapticsEnabled)

        if var updated = existing {
            updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.writtenFrom = writtenFrom
            updated.intentionID = linkedID
            store.updateScript(updated)
        } else {
            store.addScript(
                ScriptEntry(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
                    writtenFrom: writtenFrom,
                    intentionID: linkedID
                )
            )
        }

        dismiss()
    }
}
