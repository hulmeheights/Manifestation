//
//  RitualView.swift
//  Lumen
//
//  The 3-6-9. You type the line out, in full, the required number of times.
//  Typing is the whole mechanism — it is slower than reading, it occupies the
//  hands and the eyes, and it is very hard to do while thinking about
//  something else. That is the point.
//

import SwiftUI

struct RitualView: View {

    let intention: Intention
    let window: RitualWindow

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var typed: String = ""
    @State private var completed: Int = 0
    @State private var sealed: Bool = false
    @State private var sealLine: String = Library.sealLine()
    @State private var pulse: Bool = false
    @State private var recorded: Bool = false
    @FocusState private var writing: Bool

    private var target: String { intention.affirmation }
    private var totalReps: Int { window.reps }
    private var progress: Double {
        totalReps == 0 ? 0 : Double(completed) / Double(totalReps)
    }
    private var animated: Bool {
        !systemReduceMotion && !store.profile.calmMotion
    }
    private var matched: Int {
        Phrase.matchedCount(typed: typed, target: target)
    }
    private var onTrack: Bool {
        Phrase.isOnTrack(typed: typed, target: target)
    }

    var body: some View {
        CosmicScreen {
            if sealed {
                sealedScreen
            } else {
                writingScreen
            }
        }
        .onDisappear(perform: recordIfNeeded)
    }

    // MARK: - Writing

    private var writingScreen: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 26) {
                    ringCluster
                    affirmationDisplay
                    guidance
                }
                .padding(.horizontal, Metric.gutter)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            inputArea
        }
    }

    private var header: some View {
        HStack {
            Button {
                Haptics.tick(store.profile.hapticsEnabled)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.muted)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Palette.card))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(window.title.uppercased())
                    .font(.tiny11)
                    .kerning(1.6)
                    .foregroundStyle(Palette.faint)
                Text("\(completed) of \(totalReps)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText())
            }

            Spacer()

            // Balances the close button so the title stays centred.
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, 8)
    }

    private var ringCluster: some View {
        ZStack {
            if animated {
                BreathRing(animated: true, color: intention.area.tint)
                    .frame(width: 168, height: 168)
            }

            ProgressRing(
                progress: progress,
                lineWidth: 7,
                style: AnyShapeStyle(Grad.gold)
            )
            .frame(width: 132, height: 132)

            Circle()
                .strokeBorder(Palette.gold, lineWidth: 2)
                .frame(width: 132, height: 132)
                .scaleEffect(pulse ? 1.55 : 0.95)
                .opacity(pulse ? 0 : 0.75)

            VStack(spacing: 2) {
                Image(systemName: intention.area.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(intention.area.tint)
                Text("\(totalReps - completed)")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText())
                Text("to go")
                    .font(.tiny11)
                    .foregroundStyle(Palette.faint)
            }
        }
        .frame(height: 176)
    }

    /// The line, word by word. Words already typed correctly light up gold.
    private var affirmationDisplay: some View {
        FlowLayout(spacing: 7, lineSpacing: 8) {
            ForEach(Phrase.tokens(target)) { token in
                Text(token.text)
                    .font(.display(23))
                    .foregroundStyle(matched >= token.cumulative ? Palette.gold : Palette.muted.opacity(0.55))
                    .animation(.easeOut(duration: 0.18), value: matched)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var guidance: some View {
        Text(window.instruction)
            .font(.caption13)
            .foregroundStyle(Palette.faint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Input

    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 10) {
            if store.profile.tapToComplete {
                tapMode
            } else {
                typingMode
            }
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            Rectangle()
                .fill(Palette.void.opacity(0.55))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var typingMode: some View {
        VStack(spacing: 10) {
            TextField("Write it out…", text: $typed, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(Palette.ink)
                .tint(Palette.gold)
                .focused($writing)
                .submitLabel(.done)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            onTrack ? Palette.gold.opacity(0.45) : Palette.rose.opacity(0.6),
                            lineWidth: 1
                        )
                )
                .onChange(of: typed) { _, newValue in
                    if Phrase.isComplete(typed: newValue, target: target) {
                        completeRep()
                    }
                }
                .onAppear { writing = true }

            Text(onTrack ? "It completes itself when the line is finished." : "Not quite — check the line above.")
                .font(.tiny11)
                .foregroundStyle(onTrack ? Palette.faint : Palette.rose.opacity(0.9))
        }
    }

    private var tapMode: some View {
        VStack(spacing: 10) {
            Text("Say the line out loud, then tap.")
                .font(.caption13)
                .foregroundStyle(Palette.muted)

            Button {
                completeRep()
            } label: {
                Text("That's one")
            }
            .buttonStyle(.gold)
        }
    }

    // MARK: - Sealed

    private var sealedScreen: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Grad.halo(Palette.gold))
                    .frame(width: 220, height: 220)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(Grad.gold)
                    .glow(Palette.gold, radius: 24, opacity: 0.6)
            }

            Text(sealLine)
                .font(.heroSerif)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("\(totalReps.repsLabel) · \(window.title.lowercased())")
                .font(.caption13)
                .foregroundStyle(Palette.faint)

            Text(intention.affirmation)
                .font(.quoteSerif)
                .foregroundStyle(Palette.gold.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 6)

            Spacer()

            Button("Done") {
                Haptics.tick(store.profile.hapticsEnabled)
                dismiss()
            }
            .buttonStyle(.gold)
            .padding(.horizontal, Metric.gutter)
            .padding(.bottom, 24)
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func completeRep() {
        guard !sealed else { return }

        Haptics.rep(store.profile.hapticsEnabled)
        completed += 1
        typed = ""

        if animated {
            pulse = false
            withAnimation(.easeOut(duration: 0.7)) { pulse = true }
        }

        if completed >= totalReps {
            writing = false
            recordIfNeeded()
            Haptics.seal(store.profile.hapticsEnabled)
            withAnimation(.easeInOut(duration: 0.45)) { sealed = true }
        }
    }

    /// Partial sessions still count — walking away after four of six is not
    /// nothing, and pretending otherwise is how people quit.
    private func recordIfNeeded() {
        guard !recorded, completed > 0 else { return }
        recorded = true
        store.recordRitual(intentionID: intention.id, window: window, reps: completed)
    }
}

// MARK: - Launching

/// Wrapper so a ritual can be presented with `.fullScreenCover(item:)`.
struct RitualLaunch: Identifiable {
    let id = UUID()
    let intention: Intention
    let window: RitualWindow
}
