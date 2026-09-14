//
//  OnboardingView.swift
//  Lumen
//
//  Five screens, no account, no email. It ends with one line written down,
//  because an empty app is an app you never open again.
//

import SwiftUI

struct OnboardingView: View {

    @Environment(ManifestStore.self) private var store

    @State private var step: Int = 0
    @State private var name: String = ""
    @State private var area: LifeArea = .wealth
    @State private var line: String = ""
    @FocusState private var typing: Bool

    private let lastStep = 4

    var body: some View {
        CosmicScreen {
            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 26)

                footer
            }
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:  welcome
        case 1:  principles
        case 2:  nameStep
        case 3:  areaStep
        default: lineStep
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Grad.halo(Palette.gold))
                    .frame(width: 230, height: 230)

                Image(systemName: "sparkles")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(Grad.gold)
                    .glow(Palette.gold, radius: 26, opacity: 0.55)
            }

            Text("Lumen")
                .font(.system(size: 44, weight: .light, design: .serif))
                .foregroundStyle(Palette.ink)
                .kerning(3)

            Text("You have done this before. You wanted something, you held it in your head until it was ordinary, and it turned up.")
                .font(.quoteSerif)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("This is that, on purpose.")
                .font(.quoteSerif)
                .foregroundStyle(Palette.gold)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private var principles: some View {
        VStack(alignment: .leading, spacing: 26) {
            Spacer()

            Text("Three parts.\nThat's the whole thing.")
                .font(.heroSerif)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            principle(
                number: "01",
                title: "Write it down",
                body: "In the present tense, as though it already happened. A thought stays a thought until it has ink on it."
            )

            principle(
                number: "02",
                title: "Say it until it's boring",
                body: "Three times in the morning, six at midday, nine at night. Repetition is how belief gets installed — it is not mystical, it is just how minds work."
            )

            principle(
                number: "03",
                title: "Write down what shows up",
                body: "Every sign, coincidence and small win. On the days you don't believe any of it, this is the pile you read."
            )

            Spacer()
        }
    }

    private func principle(number: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.gold.opacity(0.8))
                .frame(width: 26, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.cardTitle)
                    .foregroundStyle(Palette.ink)
                Text(body)
                    .font(.caption13)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()

            Text("What should it call you?")
                .font(.heroSerif)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Your name", text: $name)
                .font(.display(26))
                .foregroundStyle(Palette.gold)
                .tint(Palette.gold)
                .focused($typing)
                .submitLabel(.next)
                .textInputAutocapitalization(.words)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Palette.stroke)
                        .frame(height: 1)
                }
                .onSubmit { advance() }

            Text("Only used to greet you. It never leaves this phone.")
                .font(.tiny11)
                .foregroundStyle(Palette.faint)

            Spacer()
        }
        .onAppear { typing = true }
    }

    private var areaStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()

            Text("What are you calling in first?")
                .font(.heroSerif)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Pick one. You can add the rest later — but one at a time is how this works.")
                .font(.caption13)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 8, lineSpacing: 8, alignment: .leading) {
                ForEach(LifeArea.allCases) { option in
                    SelectableChip(
                        text: option.title,
                        symbol: option.symbol,
                        tint: option.tint,
                        isSelected: option == area
                    ) {
                        Haptics.tick(store.profile.hapticsEnabled)
                        withAnimation(.easeOut(duration: 0.18)) {
                            area = option
                            line = option.seedAffirmation
                        }
                    }
                }
            }

            Spacer()
        }
    }

    private var lineStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Text("Say it like it's already yours.")
                .font(.heroSerif)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            TextField("I am…", text: $line, axis: .vertical)
                .lineLimit(2...4)
                .font(.display(24))
                .foregroundStyle(Palette.gold)
                .tint(Palette.gold)
                .focused($typing)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Palette.stroke, lineWidth: 1)
                )

            Text("Change it to your own words. It should sound like you on a good day.")
                .font(.tiny11)
                .foregroundStyle(Palette.faint)

            FlowLayout(spacing: 8, lineSpacing: 8, alignment: .leading) {
                ForEach(Library.starters(for: area), id: \.self) { option in
                    Button {
                        Haptics.tick(store.profile.hapticsEnabled)
                        line = option
                    } label: {
                        Text(option)
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

            Spacer()
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(0...lastStep, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? Palette.gold : Palette.stroke)
                        .frame(width: index == step ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: step)
                }
            }

            Button(action: advance) {
                Text(buttonTitle)
            }
            .buttonStyle(.gold)
            .disabled(step == lastStep && line.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)

            if step == 2 {
                Button("Skip") { advance() }
                    .font(.caption13)
                    .foregroundStyle(Palette.faint)
            } else {
                Color.clear.frame(height: 18)
            }
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 22)
    }

    private var buttonTitle: String {
        if step == 0 { return "Begin" }
        if step == lastStep { return "Plant it" }
        return "Next"
    }

    // MARK: - Flow

    private func advance() {
        Haptics.tick(store.profile.hapticsEnabled)

        if step == lastStep {
            finish()
            return
        }

        if step == 2 {
            typing = false
        }

        withAnimation(.easeInOut(duration: 0.28)) {
            step += 1
            if step == 4 && line.isEmpty {
                line = area.seedAffirmation
            }
        }
    }

    private func finish() {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLine.count >= 3 else { return }

        typing = false
        Haptics.seal(store.profile.hapticsEnabled)

        var profile = store.profile
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.startedAt = Date()
        profile.hasOnboarded = true
        store.profile = profile

        store.add(
            Intention(affirmation: trimmedLine, area: area, isFocus: true)
        )
    }
}
