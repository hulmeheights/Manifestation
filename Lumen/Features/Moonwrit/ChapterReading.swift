//
//  ChapterReading.swift
//  Lumen
//
//  The read-back. This is the belief engine and the reason the evidence log
//  exists at all — a month of small things, assembled into one page you read
//  in a single sitting.
//
//  It happens on its own at the full moon, but it's here any time you need it,
//  because the day you need it most is usually not the fourteenth.
//

import SwiftUI

struct ChapterReading: View {

    @Environment(ManifestStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.skin) private var skin

    private var start: Date { store.chapterStart }
    private var focus: Intention? { store.focusIntention }

    private var entries: [EvidenceEntry] {
        store.evidence.filter { $0.date >= start }
    }

    private var repsThisChapter: Int { store.repsThisChapter }

    var body: some View {
        NavigationStack {
            ZStack {
                NightGround()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        MoonDisc(fraction: store.moon.progress, size: 92)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)

                        Text(entries.isEmpty ? "Nothing\nyet." : "Look what\nmoved.")
                            .font(Ink.hero)
                            .foregroundStyle(skin.ink)
                            .padding(.top, 28)

                        Text(subtitle)
                            .font(Ink.body(15))
                            .foregroundStyle(skin.dim)
                            .padding(.top, 12)
                            .fixedSize(horizontal: false, vertical: true)

                        if let focus {
                            Text(focus.affirmation)
                                .font(Ink.line)
                                .foregroundStyle(skin.ink)
                                .padding(.top, 26)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        numbers.padding(.top, 24)

                        if !entries.isEmpty {
                            Eyebrow(text: "What arrived", trailing: "\(entries.count)")
                                .padding(.top, Space.section)

                            VStack(spacing: 0) {
                                ForEach(entries) { entry in
                                    readingRow(entry)
                                }
                            }
                            .padding(.top, 10)

                            Text(closing)
                                .font(Ink.body(15))
                                .foregroundStyle(skin.dim)
                                .padding(.top, Space.section)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("This chapter hasn't had anything logged in it yet. That isn't a failure — it usually means you haven't been writing things down, not that nothing happened. Start noticing: a text you weren't expecting, a name that came up twice, something that went easier than it should have.")
                                .font(Ink.body(15))
                                .foregroundStyle(skin.dim)
                                .padding(.top, Space.section)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text("Now put it down. You've done the asking — the rest isn't your department.")
                            .font(Ink.title(19))
                            .foregroundStyle(skin.ink)
                            .padding(.top, Space.section)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Chapter \(chapterNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(skin.ink)
                }
            }
        }
        .skin(store.skin)
    }

    private var chapterNumber: Int {
        let days = Date().timeIntervalSince(store.profile.startedAt) / 86_400
        return max(1, Int(days / MoonPhase.synodicMonth) + 1)
    }

    private var subtitle: String {
        let days = max(1, Int(Date().timeIntervalSince(start) / 86_400))
        if entries.isEmpty {
            return "\(days) \(days == 1 ? "day" : "days") into this chapter."
        }
        return "\(days) \(days == 1 ? "day" : "days") into this chapter, and \(entries.count) \(entries.count == 1 ? "thing has" : "things have") arrived. Read them in one go — that's the point of doing it this way."
    }

    private var closing: String {
        let caused = entries.filter { $0.kind == .win || $0.kind == .received }.count
        if caused > 0 {
            return "\(caused) of those you can point at directly. The rest you noticed because you were looking — which is exactly how this is supposed to work. You don't get more coincidences, you get better at seeing them, and then you act differently because of it."
        }
        return "None of it is proof of anything on its own. That's fine — it isn't meant to be. It's a pile, and the pile is what you read on the days you don't believe any of it."
    }

    // MARK: - Numbers

    private var numbers: some View {
        HStack(spacing: 8) {
            numberTile("\(repsThisChapter)", "reps this chapter")
            numberTile("\(entries.count)", entries.count == 1 ? "sign" : "signs")
            numberTile("\(focus?.reps ?? 0)", "held in all")
        }
    }

    private func numberTile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Ink.display(26))
                .foregroundStyle(skin.ink)
                .monospacedDigit()
            Text(label.uppercased())
                .font(Ink.tiny)
                .kerning(1.2)
                .foregroundStyle(skin.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous).fill(skin.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Space.radius, style: .continuous)
                .strokeBorder(skin.hairline, lineWidth: 1)
        )
    }

    private func readingRow(_ entry: EvidenceEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(entry.kind.title) · \(entry.date.formatted(.dateTime.day().month(.abbreviated)))".uppercased())
                .font(Ink.tiny)
                .kerning(1.4)
                .foregroundStyle(skin.evidence)

            Text(entry.text)
                .font(Ink.body(16))
                .foregroundStyle(skin.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.hairline).frame(height: 1)
        }
    }
}
