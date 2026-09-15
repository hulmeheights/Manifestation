//
//  RitualScreen.swift
//  Lumen
//
//  The 3-6-9. You type the line out in full, every time. Words take a
//  highlighter wash as you get them right, and the rep seals itself when the
//  last word lands — no button to press, no way to fake it.
//

import SwiftUI

struct RitualScreen: View {

    let intention: Intention
    let window: RitualWindow

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    @State private var typed = ""
    @State private var done = 0
    @State private var sealed = false
    @State private var sealLine = Library.sealLine()
    @State private var recorded = false
    @FocusState private var writing: Bool

    private var target: Int { window.reps }
    private var alreadyDone: Int { store.repsCompleted(in: window) }
    private var remaining: Int { max(0, target - alreadyDone) }

    var body: some View {
        ZStack {
            NightGround()

            if sealed {
                sealedView
            } else {
                writingView
            }
        }
        .skin(skin)
        .onDisappear(perform: record)
    }

    // MARK: - Writing

    private var writingView: some View {
        VStack(spacing: 0) {
            topBar

            Spacer(minLength: 0)

            VStack(spacing: 30) {
                TypedLine(target: intention.affirmation, typed: typed)
                    .padding(.horizontal, 26)

                RepMarks(total: remaining, done: done)
            }

            Spacer(minLength: 0)

            field
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tick(store.profile.hapticsEnabled)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(skin.dim)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(window.title) · rep \(min(done + 1, remaining)) of \(remaining)".uppercased())
                .font(Ink.label)
                .kerning(1.6)
                .foregroundStyle(skin.dim)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
    }

    private var field: some View {
        HStack(spacing: 12) {
            TextField("Type the line…", text: $typed, axis: .horizontal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($writing)
                .font(Ink.body(16))
                .foregroundStyle(skin.ink)
                .tint(skin.ink)
                .onChange(of: typed) { _, _ in checkRep() }

            Text("\(TypedLine.matchedCount(typed: typed, target: intention.affirmation))/\(wordCount)")
                .font(Ink.mono(11, weight: .semibold))
                .foregroundStyle(skin.dim)
                .monospacedDigit()
        }
        .padding(.horizontal, Space.gutter)
        .padding(.vertical, 18)
        .background(skin.field)
        .overlay(alignment: .top) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { writing = true }
        }
    }

    private var wordCount: Int {
        intention.affirmation.split(separator: " ").count
    }

    // MARK: - A rep lands

    private func checkRep() {
        guard !sealed else { return }
        guard TypedLine.isComplete(typed: typed, target: intention.affirmation) else { return }

        Haptics.rep(store.profile.hapticsEnabled)
        done += 1
        typed = ""

        if done >= remaining {
            record()
            withAnimation(.easeOut(duration: 0.45)) { sealed = true }
            writing = false
        }
    }

    /// Written once, whether the window was finished or abandoned halfway.
    private func record() {
        guard !recorded, done > 0 else { return }
        recorded = true
        store.recordRitual(intentionID: intention.id, window: window, reps: done)
        store.publishSnapshot()
    }

    // MARK: - Sealed

    private var sealedView: some View {
        VStack(spacing: 0) {
            Spacer()

            MoonDisc(fraction: store.moon.progress, size: 118)

            Text(sealLine)
                .font(Ink.heading)
                .foregroundStyle(skin.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 34)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(done) written · \(intention.reps + done) held in all".uppercased())
                .font(Ink.label)
                .kerning(1.6)
                .foregroundStyle(skin.dim)
                .padding(.top, 16)

            Spacer()

            Button("Done") { dismiss() }
                .buttonStyle(.outline)
                .padding(.horizontal, Space.gutter)
                .padding(.bottom, 30)
        }
        .transition(.opacity)
    }
}
