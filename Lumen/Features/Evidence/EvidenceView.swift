//
//  EvidenceView.swift
//  Lumen
//
//  The pile of proof. Doubt has a very short memory; this does not.
//

import SwiftUI

struct EvidenceView: View {

    @Environment(ManifestStore.self) private var store

    @State private var filter: EvidenceKind?
    @State private var composing = false

    private var entries: [EvidenceEntry] {
        guard let filter else { return store.evidence }
        return store.evidence.filter { $0.kind == filter }
    }

    var body: some View {
        NavigationStack {
            CosmicScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        banner
                        filters

                        if entries.isEmpty {
                            EmptyNote(
                                symbol: "eye.fill",
                                title: filter == nil ? "Nothing logged yet" : "Nothing of that kind yet",
                                message: Library.noEvidence,
                                actionTitle: "Log something",
                                action: { composing = true }
                            )
                        } else {
                            ForEach(entries) { entry in
                                EvidenceRow(entry: entry, intention: store.intention(with: entry.intentionID))
                                    .contextMenu {
                                        Button("Delete", role: .destructive) {
                                            store.deleteEvidence(entry)
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Evidence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        composing = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Palette.gold)
                    }
                }
            }
        }
        .sheet(isPresented: $composing) {
            EvidenceComposer()
        }
    }

    private var banner: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(headline)
                    .font(.titleSerif)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Read this on the days you don't believe any of it.")
                    .font(.caption13)
                    .foregroundStyle(Palette.muted)
            }
        }
    }

    private var headline: String {
        let count = store.evidenceCount
        switch count {
        case 0:  return "Start noticing."
        case 1:  return "One thing you can't explain away."
        default: return "\(count) things you can't explain away."
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectableChip(
                    text: "Everything",
                    symbol: nil,
                    tint: Palette.gold,
                    isSelected: filter == nil
                ) {
                    Haptics.tick(store.profile.hapticsEnabled)
                    withAnimation(.easeOut(duration: 0.18)) { filter = nil }
                }

                ForEach(EvidenceKind.allCases) { kind in
                    SelectableChip(
                        text: kind.title,
                        symbol: kind.symbol,
                        tint: kind.tint,
                        isSelected: filter == kind
                    ) {
                        Haptics.tick(store.profile.hapticsEnabled)
                        withAnimation(.easeOut(duration: 0.18)) {
                            filter = (filter == kind) ? nil : kind
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}
