//
//  TodayView.swift
//  Lumen
//
//  The screen you open a dozen times a day. Its job is to make starting the
//  ritual take one tap, and to put your own evidence in front of you before
//  doubt gets a word in.
//

import SwiftUI

struct TodayView: View {

    @Environment(ManifestStore.self) private var store

    @State private var launch: RitualLaunch?
    @State private var composingEvidence = false
    @State private var writingIntention = false
    @State private var showingSettings = false
    @State private var path: [Intention] = []

    var body: some View {
        NavigationStack(path: $path) {
            CosmicScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: Metric.sectionGap) {
                        greeting
                        ritualSection
                        dailyLine
                        quickCapture
                        activeSection
                        numbers
                        evidenceSection
                    }
                    .padding(.horizontal, Metric.gutter)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Palette.muted)
                    }
                }
            }
            .navigationDestination(for: Intention.self) { intention in
                IntentionDetailView(intentionID: intention.id)
            }
        }
        .fullScreenCover(item: $launch) { item in
            RitualView(intention: item.intention, window: item.window)
        }
        .sheet(isPresented: $composingEvidence) {
            EvidenceComposer()
        }
        .sheet(isPresented: $writingIntention) {
            IntentionEditorView(existing: nil)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Library.greeting(name: store.profile.name))
                .font(.heroSerif)
                .foregroundStyle(Palette.ink)

            Text(Date().longDay)
                .font(.caption13)
                .foregroundStyle(Palette.faint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Ritual

    @ViewBuilder
    private var ritualSection: some View {
        if let focus = store.focusIntention {
            ritualCard(for: focus)
        } else {
            GlassCard {
                EmptyNote(
                    symbol: "square.and.pencil",
                    title: "Start with one line",
                    message: Library.noIntentions,
                    actionTitle: "Write it down",
                    action: { writingIntention = true }
                )
            }
        }
    }

    private func ritualCard(for focus: Intention) -> some View {
        let window = store.suggestedWindow
        let done = store.isComplete(window)

        return GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Chip(
                        text: focus.area.title,
                        symbol: focus.area.symbol,
                        tint: focus.area.tint
                    )
                    Chip(
                        text: focus.charge.title,
                        symbol: "bolt.fill",
                        tint: Palette.gold
                    )
                    Spacer()
                }

                Text(focus.affirmation)
                    .font(.titleSerif)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    ZStack {
                        ProgressRing(
                            progress: store.todayProgress,
                            lineWidth: 6,
                            style: AnyShapeStyle(Grad.gold)
                        )
                        .frame(width: 54, height: 54)

                        Text("\(Int(store.todayProgress * 100))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(done ? "\(window.title) is done" : "\(window.title) · \(window.reps)×")
                            .font(.cardTitle)
                            .foregroundStyle(Palette.ink)
                        Text(done ? "Come back for the next one." : window.instruction)
                            .font(.caption13)
                            .foregroundStyle(Palette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                Button {
                    launch = RitualLaunch(intention: focus, window: window)
                } label: {
                    Text(done ? "Write it anyway" : "Begin · \(window.reps)×")
                }
                .buttonStyle(.gold)

                windowsRow
            }
        }
    }

    private var windowsRow: some View {
        HStack(spacing: 8) {
            ForEach(RitualWindow.allCases) { window in
                windowPill(window)
            }
        }
    }

    private func windowPill(_ window: RitualWindow) -> some View {
        let done = store.repsCompleted(in: window)
        let complete = done >= window.reps

        return VStack(spacing: 5) {
            Image(systemName: window.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(complete ? Palette.void : Palette.muted)

            Text("\(min(done, window.reps))/\(window.reps)")
                .font(.tiny11)
                .foregroundStyle(complete ? Palette.void : Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(complete ? AnyShapeStyle(Grad.gold) : AnyShapeStyle(Palette.raised))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Palette.stroke, lineWidth: complete ? 0 : 1)
        )
    }

    // MARK: - Daily line

    private var dailyLine: some View {
        GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.gold.opacity(0.7))

                Text(Library.dailyLine())
                    .font(.quoteSerif)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Quick capture

    private var quickCapture: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Something just happened?")

            Button {
                composingEvidence = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Log a sign, a win, a coincidence")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Palette.faint)
                }
                .foregroundStyle(Palette.ink)
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
            .buttonStyle(.plain)
        }
    }

    // MARK: - Active intentions

    @ViewBuilder
    private var activeSection: some View {
        let active = store.activeIntentions
        if active.count > 1 {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "In motion")

                VStack(spacing: 10) {
                    ForEach(Array(active.prefix(3))) { intention in
                        NavigationLink(value: intention) {
                            IntentionRow(intention: intention)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Numbers

    private var numbers: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "The proof")

            HStack(spacing: 10) {
                StatTile(
                    value: "\(store.streak)",
                    label: store.streak == 1 ? "day running" : "days running",
                    symbol: "flame.fill",
                    tint: Palette.amber
                )
                StatTile(
                    value: "\(store.totalReps)",
                    label: "lines written",
                    symbol: "pencil",
                    tint: Palette.gold
                )
                StatTile(
                    value: "\(store.receivedCount)",
                    label: "received",
                    symbol: "gift.fill",
                    tint: Palette.rose
                )
            }

            alignmentBar
        }
    }

    private var alignmentBar: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(store.alignmentLabel)
                        .font(.cardTitle)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("\(Int(store.alignment * 100))%")
                        .font(.caption13)
                        .foregroundStyle(Palette.gold)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(Grad.aurora)
                            .frame(width: max(6, proxy.size.width * store.alignment))
                    }
                }
                .frame(height: 8)

                Text("Built from your streak, your repetitions and the evidence you've logged. It only ever goes up.")
                    .font(.tiny11)
                    .foregroundStyle(Palette.faint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Evidence

    @ViewBuilder
    private var evidenceSection: some View {
        let recent = Array(store.evidence.prefix(3))
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Lately")

                VStack(spacing: 10) {
                    ForEach(recent) { entry in
                        EvidenceRow(entry: entry, intention: store.intention(with: entry.intentionID))
                    }
                }
            }
        }
    }
}
