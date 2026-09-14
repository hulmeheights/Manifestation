//
//  EvidenceComposer.swift
//  Lumen
//
//  Fast capture. Signs don't wait around while you find the right screen.
//

import SwiftUI

struct EvidenceComposer: View {

    var prefilledIntentionID: UUID? = nil

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var kind: EvidenceKind = .sign
    @State private var text: String = ""
    @State private var linkedID: UUID?
    @State private var loaded = false
    @FocusState private var writing: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool { trimmed.count >= 2 }

    var body: some View {
        NavigationStack {
            CosmicScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: Metric.sectionGap) {
                        kindPicker
                        field
                        linkPicker
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("What happened")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Log it", action: save)
                        .foregroundStyle(canSave ? Palette.gold : Palette.faint)
                        .disabled(!canSave)
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            linkedID = prefilledIntentionID
            writing = true
        }
    }

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Kind")

            FlowLayout(spacing: 8, lineSpacing: 8, alignment: .leading) {
                ForEach(EvidenceKind.allCases) { option in
                    SelectableChip(
                        text: option.title,
                        symbol: option.symbol,
                        tint: option.tint,
                        isSelected: option == kind
                    ) {
                        Haptics.tick(store.profile.hapticsEnabled)
                        withAnimation(.easeOut(duration: 0.18)) { kind = option }
                    }
                }
            }

            Text(kind.prompt)
                .font(.tiny11)
                .foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var field: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "In your words")

            TextField("Write it before you talk yourself out of it…", text: $text, axis: .vertical)
                .lineLimit(3...8)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(Palette.ink)
                .tint(Palette.gold)
                .focused($writing)
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
                SectionHeader(title: "Tie it to an intention")

                VStack(spacing: 8) {
                    ForEach(options) { intention in
                        Button {
                            Haptics.tick(store.profile.hapticsEnabled)
                            linkedID = (linkedID == intention.id) ? nil : intention.id
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: linkedID == intention.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(linkedID == intention.id ? Palette.gold : Palette.faint)

                                Text(intention.affirmation)
                                    .font(.body15)
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)

                                Spacer(minLength: 0)

                                Image(systemName: intention.area.symbol)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(intention.area.tint)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Palette.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        linkedID == intention.id ? Palette.gold.opacity(0.45) : Palette.stroke,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Optional. Linked evidence shows up on that intention's page.")
                    .font(.tiny11)
                    .foregroundStyle(Palette.faint)
            }
        }
    }

    private func save() {
        guard canSave else { return }
        Haptics.seal(store.profile.hapticsEnabled)
        store.addEvidence(
            EvidenceEntry(kind: kind, text: trimmed, intentionID: linkedID)
        )
        dismiss()
    }
}
