//
//  IntentionsView.swift
//  Lumen
//
//  Everything written down, split into what's still coming and what landed.
//

import SwiftUI

struct IntentionsView: View {

    @Environment(ManifestStore.self) private var store

    @State private var showingReceived = false
    @State private var writing = false

    private var list: [Intention] {
        showingReceived ? store.receivedIntentions : store.activeIntentions
    }

    var body: some View {
        NavigationStack {
            CosmicScreen {
                ScrollView {
                    VStack(spacing: 14) {
                        picker

                        if list.isEmpty {
                            emptyState
                        } else {
                            ForEach(list) { intention in
                                NavigationLink(value: intention) {
                                    IntentionRow(intention: intention)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Intentions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        writing = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Palette.gold)
                    }
                }
            }
            .navigationDestination(for: Intention.self) { intention in
                IntentionDetailView(intentionID: intention.id)
            }
        }
        .sheet(isPresented: $writing) {
            IntentionEditorView(existing: nil)
        }
    }

    private var picker: some View {
        HStack(spacing: 8) {
            segment(title: "In motion", count: store.activeIntentions.count, selected: !showingReceived) {
                showingReceived = false
            }
            segment(title: "Received", count: store.receivedIntentions.count, selected: showingReceived) {
                showingReceived = true
            }
        }
    }

    private func segment(
        title: String,
        count: Int,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tick(store.profile.hapticsEnabled)
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("\(count)")
                    .font(.tiny11)
                    .opacity(0.7)
            }
            .foregroundStyle(selected ? Palette.void : Palette.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(selected ? AnyShapeStyle(Grad.gold) : AnyShapeStyle(Palette.raised))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var emptyState: some View {
        if showingReceived {
            EmptyNote(
                symbol: "gift.fill",
                title: "The archive is empty",
                message: Library.noReceived
            )
        } else {
            EmptyNote(
                symbol: "square.and.pencil",
                title: "Nothing written down",
                message: Library.noIntentions,
                actionTitle: "Write one",
                action: { writing = true }
            )
        }
    }
}
