//
//  PictureScreen.swift
//  Moonwrit
//
//  The Picture — visualisation. Writing convinces the mind; this makes the
//  picture specific, which is what makes it feel already true.
//
//  Two rules, both deliberate:
//   · No timer. You tap Next when you're ready, however long that takes.
//   · A clock that counts UP, so going slowly is rewarded rather than rushed.
//

import SwiftUI

struct PictureScreen: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.skin) private var skin

    private enum Stage: Equatable {
        case intro
        case prompt(Int)
        case close
        case writing
        case done
    }

    @State private var stage: Stage = .intro
    @State private var startedAt: Date?
    @State private var elapsed: TimeInterval = 0
    @State private var note = ""
    @FocusState private var writingNote: Bool

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var prompts: [String] { Library.picturePrompts }
    private var focus: Intention? { store.focusIntention }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            switch stage {
            case .intro:            intro
            case .prompt(let index): promptView(index)
            case .close:            closing
            case .writing:          writingView
            case .done:             doneView
            }
        }
        .onReceive(tick) { _ in
            guard let startedAt, stage != .done, stage != .intro else { return }
            elapsed = Date().timeIntervalSince(startedAt)
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            if stage == .intro {
                Text("The Picture".uppercased())
                    .font(Ink.label)
                    .kerning(1.8)
                    .foregroundStyle(skin.dim)
            } else {
                Button {
                    back()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(skin.dim)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if store.profile.showVisualisationClock, startedAt != nil, stage != .done {
                Text(clockText)
                    .font(Ink.mono(12, weight: .medium))
                    .foregroundStyle(skin.dim)
                    .monospacedDigit()
                    .accessibilityLabel("Visualising for \(clockText)")
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, 14)
        .frame(height: 46)
    }

    private var clockText: String {
        let total = Int(elapsed)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            MoonDisc(fraction: store.moon.progress, size: 86)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("You're\nalready there.")
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .padding(.top, 34)

            Text(Library.pictureIntro)
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .padding(.top, 14)
                .fixedSize(horizontal: false, vertical: true)

            if let focus {
                Text(focus.affirmation)
                    .font(Ink.body(15, weight: .bold))
                    .foregroundStyle(skin.ink)
                    .padding(.top, 22)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(Library.pictureRule)
                .font(Ink.small)
                .foregroundStyle(skin.evidence)
                .padding(.top, 16)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button("Begin") { begin() }
                .buttonStyle(.ink)
                .padding(.bottom, 22)
        }
        .padding(.horizontal, Space.gutter)
    }

    // MARK: - A prompt

    private func promptView(_ index: Int) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Text(prompts[index])
                .font(Ink.heading)
                .foregroundStyle(skin.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 26)
                .id(index)
                .transition(.opacity)

            Text("Answer it in the present, from inside it.")
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 30)

            Spacer()

            HStack(spacing: 5) {
                ForEach(prompts.indices, id: \.self) { dot in
                    Circle()
                        .fill(dot <= index ? skin.ink : skin.track)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.bottom, 22)

            Button(index == prompts.count - 1 ? "Last one" : "Next") {
                advance(from: index)
            }
            .buttonStyle(.ink)
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, 22)
        }
    }

    // MARK: - Closing

    private var closing: some View {
        VStack(spacing: 0) {
            Spacer()

            MoonDisc(fraction: store.moon.progress, size: 110)

            if let focus {
                Text(focus.affirmation)
                    .font(Ink.line)
                    .foregroundStyle(skin.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 34)
                    .padding(.horizontal, 30)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(Library.pictureClose)
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(Library.pictureAsk) {
                withAnimation { stage = .writing }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { writingNote = true }
            }
            .buttonStyle(.ink)
            .padding(.horizontal, Space.gutter)

            Button("Finish without writing") { finish(saving: false) }
                .buttonStyle(.outline)
                .padding(.horizontal, Space.gutter)
                .padding(.top, 10)
                .padding(.bottom, 22)
        }
    }

    // MARK: - Writing it down

    private var writingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Library.pictureAsk)
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .padding(.top, 10)

            Text(Library.pictureAskDetail)
                .font(Ink.small)
                .foregroundStyle(skin.dim)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)

            TextField("", text: $note, axis: .vertical)
                .lineLimit(4...10)
                .focused($writingNote)
                .font(Ink.body(16))
                .foregroundStyle(skin.ink)
                .tint(skin.ink)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.field)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                        .strokeBorder(skin.hairline, lineWidth: 1)
                )
                .padding(.top, 20)

            Spacer()

            Button("Keep it") { finish(saving: true) }
                .buttonStyle(.ink)
                .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                .padding(.bottom, 22)
        }
        .padding(.horizontal, Space.gutter)
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 0) {
            Spacer()

            MoonDisc(fraction: store.moon.progress, size: 96)

            Text("Held.")
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .padding(.top, 30)

            Text("\(clockText) with your eyes on it.".uppercased())
                .font(Ink.label)
                .kerning(1.6)
                .foregroundStyle(skin.dim)
                .padding(.top, 14)

            Spacer()

            Button("Again") { reset() }
                .buttonStyle(.outline)
                .padding(.horizontal, Space.gutter)
                .padding(.bottom, 22)
        }
    }

    // MARK: - Flow

    private func begin() {
        startedAt = Date()
        elapsed = 0
        withAnimation(.easeInOut(duration: 0.3)) { stage = .prompt(0) }
    }

    private func advance(from index: Int) {
        Haptics.tick(store.profile.hapticsEnabled)
        withAnimation(.easeInOut(duration: 0.3)) {
            stage = index + 1 < prompts.count ? .prompt(index + 1) : .close
        }
    }

    private func back() {
        withAnimation(.easeInOut(duration: 0.25)) {
            switch stage {
            case .prompt(let index):
                stage = index == 0 ? .intro : .prompt(index - 1)
            case .close:
                stage = .prompt(prompts.count - 1)
            case .writing:
                stage = .close
            default:
                stage = .intro
            }
        }
    }

    private func finish(saving: Bool) {
        if saving {
            let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                store.addScript(
                    ScriptEntry(
                        title: "What I saw",
                        body: text,
                        writtenFrom: Date(),
                        intentionID: focus?.id
                    )
                )
            }
        }
        Haptics.seal(store.profile.hapticsEnabled)
        withAnimation(.easeInOut(duration: 0.35)) { stage = .done }
    }

    private func reset() {
        note = ""
        startedAt = nil
        elapsed = 0
        withAnimation { stage = .intro }
    }
}
