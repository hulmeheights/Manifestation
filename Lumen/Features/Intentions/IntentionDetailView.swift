//
//  IntentionDetailView.swift
//  Lumen
//

import SwiftUI

struct IntentionDetailView: View {

    let intentionID: UUID

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var launch: RitualLaunch?
    @State private var editing = false
    @State private var confirmingReceived = false
    @State private var receivedNote = ""
    @State private var confirmingDelete = false

    private var intention: Intention? { store.intention(with: intentionID) }

    var body: some View {
        CosmicScreen {
            if let intention {
                ScrollView {
                    VStack(alignment: .leading, spacing: Metric.sectionGap) {
                        hero(intention)
                        details(intention)
                        beginSection(intention)
                        actions(intention)
                        linkedEvidence(intention)
                        linkedScripts(intention)
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            } else {
                EmptyNote(
                    symbol: "sparkles",
                    title: "Gone",
                    message: "This intention is no longer in your practice."
                )
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Palette.muted)
                }
                .disabled(intention == nil)
            }
        }
        .fullScreenCover(item: $launch) { item in
            RitualView(intention: item.intention, window: item.window)
        }
        .sheet(isPresented: $editing) {
            IntentionEditorView(existing: intention)
        }
        .alert("It arrived?", isPresented: $confirmingReceived) {
            TextField("How did it come? (optional)", text: $receivedNote)
            Button("Cancel", role: .cancel) { receivedNote = "" }
            Button("Received") { markReceived() }
        } message: {
            Text("This moves it into your archive and files it as evidence. That archive is the reason you'll trust this next time.")
        }
        .confirmationDialog(
            "Delete this intention?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let intention {
                    store.delete(intention)
                    dismiss()
                }
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Its repetitions and linked evidence go too. This can't be undone.")
        }
    }

    // MARK: - Hero

    private func hero(_ intention: Intention) -> some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Grad.halo(intention.area.tint))
                    .frame(width: 200, height: 200)

                ProgressRing(
                    progress: intention.chargeProgress,
                    lineWidth: 7,
                    style: AnyShapeStyle(Grad.gold)
                )
                .frame(width: 136, height: 136)

                VStack(spacing: 1) {
                    Text("\(intention.reps)")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                    Text("written")
                        .font(.tiny11)
                        .foregroundStyle(Palette.faint)
                }
            }
            .frame(height: 200)

            Text(intention.affirmation)
                .font(.heroSerif)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Chip(text: intention.area.title, symbol: intention.area.symbol, tint: intention.area.tint)
                Chip(text: intention.charge.title, symbol: "bolt.fill", tint: Palette.gold)
                Chip(text: intention.stage.title, symbol: intention.stage.symbol, tint: Palette.muted)
            }

            Text(intention.charge.blurb)
                .font(.caption13)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Details

    @ViewBuilder
    private func details(_ intention: Intention) -> some View {
        let hasFeeling = !intention.feeling.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDetail = !intention.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasFeeling || hasDetail || intention.byDate != nil {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "The shape of it")

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        if hasFeeling {
                            labelled("How it feels", intention.feeling)
                        }
                        if hasDetail {
                            labelled("Notes", intention.detail)
                        }
                        if let byDate = intention.byDate {
                            labelled("Held for", byDate.longDay)
                        }
                        labelled("Written", "\(intention.createdAt.shortDay) · \(intention.daysHeld.daysLabel) ago")
                    }
                }
            }
        }
    }

    private func labelled(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.tiny11)
                .kerning(1.2)
                .foregroundStyle(Palette.faint)
            Text(value)
                .font(.body15)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Begin

    @ViewBuilder
    private func beginSection(_ intention: Intention) -> some View {
        if intention.stage != .received {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Write it")

                HStack(spacing: 8) {
                    ForEach(RitualWindow.allCases) { window in
                        Button {
                            launch = RitualLaunch(intention: intention, window: window)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: window.symbol)
                                    .font(.system(size: 15, weight: .semibold))
                                Text("\(window.reps)×")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Text(window.title)
                                    .font(.tiny11)
                                    .opacity(0.75)
                            }
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Palette.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        store.isComplete(window) ? Palette.gold.opacity(0.5) : Palette.stroke,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func actions(_ intention: Intention) -> some View {
        VStack(spacing: 10) {
            if intention.stage == .received {
                Button("Put it back in motion") {
                    store.returnToActive(intention)
                }
                .buttonStyle(.ghost)
            } else {
                Button("It arrived") {
                    confirmingReceived = true
                }
                .buttonStyle(.gold)

                if !intention.isFocus {
                    Button("Make this my focus") {
                        Haptics.tick(store.profile.hapticsEnabled)
                        store.setFocus(intention)
                    }
                    .buttonStyle(.ghost)
                }
            }

            Button("Delete") {
                confirmingDelete = true
            }
            .buttonStyle(GhostButtonStyle(tint: Palette.rose, compact: true))
        }
    }

    // MARK: - Linked

    @ViewBuilder
    private func linkedEvidence(_ intention: Intention) -> some View {
        let entries = store.evidenceLinked(to: intention.id)
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Evidence · \(entries.count)")
                VStack(spacing: 10) {
                    ForEach(entries) { entry in
                        EvidenceRow(entry: entry, intention: nil)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func linkedScripts(_ intention: Intention) -> some View {
        let entries = store.scriptsLinked(to: intention.id)
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Scripted · \(entries.count)")
                VStack(spacing: 10) {
                    ForEach(entries) { entry in
                        ScriptRow(entry: entry)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func markReceived() {
        guard let intention else { return }
        Haptics.received(store.profile.hapticsEnabled)
        store.markReceived(intention, note: receivedNote)
        receivedNote = ""
    }
}
