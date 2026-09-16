//
//  OpeningScreen.swift
//  Lumen
//
//  The first five minutes. Rebuilt in the night face — the old gold-and-glass
//  opening was the last thing left over from the app this used to be.
//
//  Four steps and no more: what this is, your name, what you want, and the
//  line itself. Nothing is asked for that isn't used immediately.
//

import SwiftUI

struct OpeningScreen: View {

    @Environment(ManifestStore.self) private var store

    @State private var step = 0
    @State private var name = ""
    @State private var area: LifeArea = .wealth
    @State private var line = ""
    @FocusState private var typing: Bool

    private let lastStep = 3
    private var skin: Skin { store.skin }

    var body: some View {
        ZStack {
            NightGround()

            VStack(spacing: 0) {

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        switch step {
                        case 0:  welcome
                        case 1:  nameStep
                        case 2:  areaStep
                        default: lineStep
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)

                footer
            }
        }
        .skin(skin)
    }

    // MARK: - 0 · What this is

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {

            MoonDisc(fraction: store.moon.progress, size: 130)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40)

            Text("Moonwrit")
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .padding(.top, 36)

            Text("You write one sentence about your life as though it has already happened. Three times in the morning, six in the afternoon, nine at night. Then you go and act like the person it describes, and you write down what turns up.")
                .font(Ink.body(16))
                .foregroundStyle(skin.dim)
                .padding(.top, 16)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 0) {
                point("3 · 6 · 9", "Writing it by hand is slower than thinking it, and slow is the point. Eighteen times a day is enough to wear a groove.")
                point("The moon", "The month gives the practice a shape. The new moon is for asking, the full moon is for reading back what arrived. Nothing expires.")
                point("The evidence", "You log what shows up, however small. On the days you don't believe any of it, that pile is what you read.")
            }
            .padding(.top, 28)

            Text("Everything stays on this phone. Nothing is uploaded anywhere.")
                .font(Ink.small)
                .foregroundStyle(skin.ghost)
                .padding(.top, 24)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func point(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(Ink.tiny)
                .kerning(1.6)
                .foregroundStyle(skin.evidence)
            Text(body)
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }

    // MARK: - 1 · Name

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "One of four").padding(.top, 40)

            Text("What should\nit call you?")
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .padding(.top, 14)

            Text("Only used to address you. Leave it blank if you'd rather not.")
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)

            field(text: $name, placeholder: "Your name")
                .padding(.top, 24)
                .textInputAutocapitalization(.words)
        }
    }

    // MARK: - 2 · Area

    private var areaStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Two of four").padding(.top, 40)

            Text("Where does\nit go first?")
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .padding(.top, 14)

            Text("One at a time. You can run as many lines as you like later — only one sits in the light at once, because attention doesn't divide.")
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(LifeArea.allCases) { option in
                    areaRow(option)
                }
            }
            .padding(.top, 18)
        }
    }

    private func areaRow(_ option: LifeArea) -> some View {
        Button {
            let wasSeed = LifeArea.allCases.contains { $0.seedAffirmation == line }
            area = option
            if line.isEmpty || wasSeed { line = option.seedAffirmation }
            Haptics.tick(store.profile.hapticsEnabled)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: area == option ? "checkmark.circle.fill" : option.symbol)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(area == option ? skin.evidence : skin.dim)
                    .frame(width: 24)

                Text(option.title)
                    .font(Ink.body(17, weight: area == option ? .bold : .medium))
                    .foregroundStyle(skin.ink)

                Spacer()
            }
            .padding(.vertical, 15)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(skin.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3 · The line

    private var lineStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Three of four").padding(.top, 40)

            Text("Write it as\nalready true.")
                .font(Ink.hero)
                .foregroundStyle(skin.ink)
                .padding(.top, 14)

            Text("Present tense, one breath long, no \u{201C}not\u{201D} or \u{201C}never\u{201D} in it. \u{201C}I will have\u{201D} is a sentence about not having it. Change the starting line below into your own words.")
                .font(Ink.body(15))
                .foregroundStyle(skin.dim)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)

            field(text: $line, placeholder: area.seedAffirmation, big: true)
                .padding(.top, 24)
                .focused($typing)

            if !checks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(checks, id: \.self) { note in
                        Text("· " + note)
                            .font(Ink.small)
                            .foregroundStyle(skin.evidence)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 14)
            }

            Text("You can change it whenever you like. Nothing here is a contract.")
                .font(Ink.tiny)
                .foregroundStyle(skin.ghost)
                .padding(.top, 20)
        }
    }

    private var checks: [String] {
        let text = line.lowercased()
        var notes: [String] = []
        if text.contains("will ") || text.contains("going to") {
            notes.append("\u{201C}Will\u{201D} keeps it in the future. Try the present.")
        }
        if text.contains(" not ") || text.contains("n't") || text.contains("never") {
            notes.append("Say what you want, not what you don't.")
        }
        if line.trimmingCharacters(in: .whitespacesAndNewlines).count > 120 {
            notes.append("Long for one breath. Shorter sticks harder.")
        }
        return notes
    }

    // MARK: - Field

    private func field(text: Binding<String>, placeholder: String, big: Bool = false) -> some View {
        TextField("", text: text, axis: .vertical)
            .font(big ? Ink.line : Ink.body(17))
            .foregroundStyle(skin.ink)
            .tint(skin.evidence)
            .lineLimit(big ? 2...5 : 1...2)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.field)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                    .strokeBorder(skin.hairline, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(big ? Ink.line : Ink.body(17))
                        .foregroundStyle(skin.ghost)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(0...lastStep, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? skin.ink : skin.hairline)
                        .frame(width: index == step ? 18 : 6, height: 5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: step)
                }
            }

            Button(buttonTitle) { advance() }
                .buttonStyle(.ink)
                .frame(maxWidth: .infinity)
                .disabled(step == lastStep && line.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)

            if step > 0 {
                Button("Back") {
                    typing = false
                    step -= 1
                }
                .buttonStyle(.plain)
                .font(Ink.small)
                .foregroundStyle(skin.dim)
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(alignment: .top) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }

    private var buttonTitle: String {
        switch step {
        case 0:        return "Begin"
        case lastStep: return "Plant it"
        default:       return "Next"
        }
    }

    private func advance() {
        Haptics.tick(store.profile.hapticsEnabled)

        if step == lastStep {
            finish()
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) { step += 1 }

        if step == lastStep && line.isEmpty {
            line = area.seedAffirmation
        }
    }

    private func finish() {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLine.count >= 3 else { return }

        typing = false
        Haptics.seal(store.profile.hapticsEnabled)

        store.add(Intention(affirmation: trimmedLine, area: area, isFocus: true))

        var profile = store.profile
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.startedAt = Date()
        profile.hasOnboarded = true
        store.profile = profile
    }
}
