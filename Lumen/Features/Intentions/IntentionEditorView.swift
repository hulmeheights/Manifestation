//
//  IntentionEditorView.swift
//  Lumen
//
//  Writing it down. The screen nudges toward the present tense, because an
//  affirmation in the future tense keeps the thing permanently in the future.
//

import SwiftUI

struct IntentionEditorView: View {

    let existing: Intention?

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var affirmation: String = ""
    @State private var area: LifeArea = .spirit
    @State private var feeling: String = ""
    @State private var detail: String = ""
    @State private var hasDate: Bool = false
    @State private var byDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 90)
    @State private var isFocus: Bool = false
    @State private var showingRules: Bool = false
    @State private var loaded: Bool = false

    private var isEditing: Bool { existing != nil }

    private var trimmed: String {
        affirmation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool { trimmed.count >= 3 }

    var body: some View {
        NavigationStack {
            CosmicScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: Metric.sectionGap) {
                        lineField
                        areaPicker
                        feelingField
                        extras
                        rules
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(isEditing ? "Edit" : "Write it down")
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
            .safeAreaInset(edge: .bottom) {
                Button(isEditing ? "Save changes" : "Plant it", action: save)
                    .buttonStyle(.gold)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.45)
                    .padding(.horizontal, Metric.gutter)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [Palette.void.opacity(0), Palette.void.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
            }
        }
        .onAppear(perform: loadOnce)
    }

    // MARK: - The line

    private var lineField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "The line")

            TextField("I am…", text: $affirmation, axis: .vertical)
                .lineLimit(2...5)
                .font(.display(22))
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

            Text("Present tense. Short enough to say in one breath. You're going to write this hundreds of times.")
                .font(.tiny11)
                .foregroundStyle(Palette.faint)
                .fixedSize(horizontal: false, vertical: true)

            starters
        }
    }

    private var starters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Borrow one to start")
                .font(.tiny11)
                .foregroundStyle(Palette.faint)

            FlowLayout(spacing: 8, lineSpacing: 8, alignment: .leading) {
                ForEach(Library.starters(for: area), id: \.self) { line in
                    Button {
                        Haptics.tick(store.profile.hapticsEnabled)
                        affirmation = line
                    } label: {
                        Text(line)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.muted)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Palette.raised))
                            .overlay(Capsule().strokeBorder(Palette.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Area

    private var areaPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Which part of your life")

            FlowLayout(spacing: 8, lineSpacing: 8, alignment: .leading) {
                ForEach(LifeArea.allCases) { option in
                    SelectableChip(
                        text: option.title,
                        symbol: option.symbol,
                        tint: option.tint,
                        isSelected: option == area
                    ) {
                        Haptics.tick(store.profile.hapticsEnabled)
                        withAnimation(.easeOut(duration: 0.18)) { area = option }
                    }
                }
            }
        }
    }

    // MARK: - Feeling

    private var feelingField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How does it feel to already have it")

            WritingField(
                placeholder: "Light. Unbothered. Like it was always mine.",
                text: $feeling,
                axis: .vertical,
                lineLimit: 2...4
            )

            Text("The feeling does the work. Keep coming back to this one.")
                .font(.tiny11)
                .foregroundStyle(Palette.faint)
        }
    }

    // MARK: - Extras

    private var extras: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Anything else")

            WritingField(
                placeholder: "Notes, detail, the specifics…",
                text: $detail,
                axis: .vertical,
                lineLimit: 2...6
            )

            GlassCard(padding: 14) {
                VStack(spacing: 12) {
                    Toggle(isOn: $hasDate) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hold a date")
                                .font(.body15)
                                .foregroundStyle(Palette.ink)
                            Text("Not a deadline. Somewhere to point.")
                                .font(.tiny11)
                                .foregroundStyle(Palette.faint)
                        }
                    }
                    .tint(Palette.gold)

                    if hasDate {
                        DatePicker(
                            "By",
                            selection: $byDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .font(.body15)
                        .foregroundStyle(Palette.muted)
                        .tint(Palette.gold)
                    }

                    Divider().overlay(Palette.stroke)

                    Toggle(isOn: $isFocus) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Make this my focus")
                                .font(.body15)
                                .foregroundStyle(Palette.ink)
                            Text("The one the daily ritual opens with.")
                                .font(.tiny11)
                                .foregroundStyle(Palette.faint)
                        }
                    }
                    .tint(Palette.gold)
                }
            }
        }
    }

    // MARK: - Rules

    private var rules: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { showingRules.toggle() }
            } label: {
                HStack {
                    Text("How to write one that works")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.gold)
                    Spacer()
                    Image(systemName: showingRules ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.faint)
                }
            }
            .buttonStyle(.plain)

            if showingRules {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Library.rules) { rule in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(rule.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            Text(rule.detail)
                                .font(.caption13)
                                .foregroundStyle(Palette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Metric.tileRadius, style: .continuous)
                        .fill(Palette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Metric.tileRadius, style: .continuous)
                        .strokeBorder(Palette.stroke, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Load / save

    private func loadOnce() {
        guard !loaded else { return }
        loaded = true
        guard let existing else { return }
        affirmation = existing.affirmation
        area = existing.area
        feeling = existing.feeling
        detail = existing.detail
        isFocus = existing.isFocus
        if let date = existing.byDate {
            hasDate = true
            byDate = date
        }
    }

    private func save() {
        guard canSave else { return }
        Haptics.tick(store.profile.hapticsEnabled)

        if var updated = existing {
            updated.affirmation = trimmed
            updated.area = area
            updated.feeling = feeling.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.byDate = hasDate ? byDate : nil
            updated.isFocus = isFocus
            store.update(updated)
        } else {
            let new = Intention(
                affirmation: trimmed,
                area: area,
                feeling: feeling.trimmingCharacters(in: .whitespacesAndNewlines),
                detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                byDate: hasDate ? byDate : nil,
                isFocus: isFocus
            )
            store.add(new)
        }

        dismiss()
    }
}
