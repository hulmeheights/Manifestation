//
//  ScriptingView.swift
//  Lumen
//
//  Scripting: writing from a day that hasn't happened yet, in the past tense,
//  as though you're telling someone how it went.
//

import SwiftUI

struct ScriptRow: View {
    let entry: ScriptEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.lilac)

                Text(entry.writtenFrom.longDay)
                    .font(.tiny11)
                    .foregroundStyle(Palette.lilac.opacity(0.9))

                Spacer(minLength: 0)

                Text(entry.createdAt.relativeDayLabel)
                    .font(.tiny11)
                    .foregroundStyle(Palette.faint)
            }

            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.cardTitle)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
            }

            Text(entry.body)
                .font(.body15)
                .foregroundStyle(Palette.muted)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct ScriptingView: View {

    @Environment(ManifestStore.self) private var store

    @State private var writing = false
    @State private var editing: ScriptEntry?

    var body: some View {
        NavigationStack {
            CosmicScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        explainer

                        if store.scripts.isEmpty {
                            EmptyNote(
                                symbol: "book.closed.fill",
                                title: "Write from the other side",
                                message: Library.noScripts,
                                actionTitle: "Start one",
                                action: { writing = true }
                            )
                        } else {
                            ForEach(store.scripts) { entry in
                                Button {
                                    editing = entry
                                } label: {
                                    ScriptRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        store.deleteScript(entry)
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
            .navigationTitle("Scripting")
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
        }
        .sheet(isPresented: $writing) {
            ScriptEditorView(existing: nil)
        }
        .sheet(item: $editing) { entry in
            ScriptEditorView(existing: entry)
        }
    }

    private var explainer: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Past tense. Always.")
                    .font(.titleSerif)
                    .foregroundStyle(Palette.ink)

                Text("Pick a date ahead of you, then write about it as though it has already been and gone. Detail is the whole trick — the smell of the room, what you were wearing, who you rang first.")
                    .font(.caption13)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
