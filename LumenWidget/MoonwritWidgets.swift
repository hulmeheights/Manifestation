//
//  MoonwritWidgets.swift
//
//  ⚠️  THIS FILE IS NOT IN THE APP TARGET AND MUST NOT BE.
//
//  It belongs to a Widget Extension target you create in Xcode:
//      File → New → Target… → Widget Extension
//      Name it "MoonwritWidget", untick "Include Live Activity",
//      tick "Include Configuration Intent".
//
//  Then:
//   1. Delete the placeholder .swift file Xcode generates, and drag this file
//      into the new target instead.
//   2. Select the App Group capability on BOTH targets (app + widget) and use
//      the same identifier as SharedStore.appGroup.
//   3. Tick the widget target's membership on these three files, in the File
//      Inspector on the right:
//          Lumen/Core/MoonPhase.swift
//          Lumen/Core/SharedSnapshot.swift
//          Lumen/Design/Moonlight.swift
//
//  Both widgets below are permanent. The Lock Screen one is a widget, not a
//  Live Activity — it stays where you put it and never expires.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - What the user can customise

enum WidgetSkinChoice: String, AppEnum {
    case matchDevice
    case night
    case day

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"

    static let caseDisplayRepresentations: [WidgetSkinChoice: DisplayRepresentation] = [
        .matchDevice: DisplayRepresentation(title: "Match device"),
        .night: DisplayRepresentation(title: "Night"),
        .day: DisplayRepresentation(title: "Day")
    ]
}

enum WidgetContent: String, AppEnum {
    case line
    case moon
    case reps

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Show"

    static let caseDisplayRepresentations: [WidgetContent: DisplayRepresentation] = [
        .line: DisplayRepresentation(title: "Your line"),
        .moon: DisplayRepresentation(title: "Tonight's moon"),
        .reps: DisplayRepresentation(title: "Today's reps")
    ]
}

struct MoonwritConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Moonwrit"
    static let description = IntentDescription("Your line, tonight's moon, and where you are in the nine.")

    @Parameter(title: "Theme", default: .matchDevice)
    var theme: WidgetSkinChoice

    @Parameter(title: "Lead with", default: .line)
    var lead: WidgetContent

    @Parameter(title: "Show the moon", default: true)
    var showMoon: Bool
}

// MARK: - Timeline
//
// Refreshed on the hour. The moon is recomputed from the date inside each
// entry, so the widget stays truthful even if the app hasn't been opened.

struct MoonwritEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedSnapshot
    let configuration: MoonwritConfiguration

    var moon: MoonMoment { MoonPhase.moment(date) }
}

struct MoonwritProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> MoonwritEntry {
        MoonwritEntry(date: Date(), snapshot: .placeholder, configuration: MoonwritConfiguration())
    }

    func snapshot(for configuration: MoonwritConfiguration, in context: Context) async -> MoonwritEntry {
        MoonwritEntry(
            date: Date(),
            snapshot: context.isPreview ? .placeholder : SharedStore.read(),
            configuration: configuration
        )
    }

    func timeline(for configuration: MoonwritConfiguration, in context: Context) async -> Timeline<MoonwritEntry> {
        let now = Date()
        let saved = SharedStore.read()

        // One entry an hour for the next twelve, so the moon and the window
        // label move on their own between app launches.
        var entries: [MoonwritEntry] = []
        for hour in 0..<12 {
            let date = Calendar.current.date(byAdding: .hour, value: hour, to: now) ?? now
            entries.append(MoonwritEntry(date: date, snapshot: saved, configuration: configuration))
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Resolving the theme

private extension MoonwritEntry {
    func resolvedSkin(_ scheme: ColorScheme) -> Skin {
        switch configuration.theme {
        case .night:       return .night
        case .day:         return .day
        case .matchDevice: return scheme == .dark ? .night : .day
        }
    }
}

// MARK: - Home Screen

struct HomeWidgetView: View {
    let entry: MoonwritEntry
    @Environment(\.colorScheme) private var scheme
    @Environment(\.widgetFamily) private var family

    private var skin: Skin { entry.resolvedSkin(scheme) }

    var body: some View {
        Group {
            switch family {
            case .systemSmall: small
            default:           medium
            }
        }
        .skin(skin)
        .containerBackground(for: .widget) {
            ZStack {
                skin.ground
                if skin.stars { NightStars(count: 40) }
            }
        }
    }

    // MARK: Small

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if entry.configuration.showMoon {
                    MoonDisc(fraction: entry.moon.progress, size: 22, glowing: false)
                }
                Spacer(minLength: 0)
                Text("\(entry.snapshot.repsToday)/\(entry.snapshot.repsTarget)")
                    .font(Ink.mono(11, weight: .semibold))
                    .foregroundStyle(skin.dim)
            }

            Spacer(minLength: 6)

            if entry.configuration.lead == .reps || !entry.snapshot.hasLine {
                Text("\(entry.snapshot.repsHeld)")
                    .font(Ink.display(30))
                    .foregroundStyle(skin.ink)
                Text("reps held")
                    .font(Ink.tiny)
                    .foregroundStyle(skin.dim)
            } else {
                Text(entry.snapshot.hasLine ? entry.snapshot.line : "Write your line.")
                    .font(Ink.body(13, weight: .bold))
                    .foregroundStyle(skin.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 6)
            Meter(progress: entry.snapshot.progress, height: 3)
        }
    }

    // MARK: Medium

    private var medium: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.moon.phase.title.uppercased())
                    .font(Ink.tiny)
                    .kerning(1.6)
                    .foregroundStyle(skin.dim)

                Spacer(minLength: 8)

                Text(entry.snapshot.hasLine ? entry.snapshot.line : "Write your line.")
                    .font(Ink.body(17, weight: .bold))
                    .foregroundStyle(skin.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 10)

                HStack(spacing: 10) {
                    Text("\(entry.snapshot.repsToday) of \(entry.snapshot.repsTarget) today")
                        .font(Ink.mono(11, weight: .semibold))
                        .foregroundStyle(skin.dim)
                    if entry.snapshot.evidenceThisChapter > 0 {
                        Text("· \(entry.snapshot.evidenceThisChapter) signs")
                            .font(Ink.mono(11, weight: .semibold))
                            .foregroundStyle(skin.evidence)
                    }
                }
                Meter(progress: entry.snapshot.progress, height: 3)
                    .padding(.top, 6)
            }

            if entry.configuration.showMoon {
                MoonDisc(fraction: entry.moon.progress, size: 62)
            }
        }
    }
}

struct MoonwritHomeWidget: Widget {
    let kind = "MoonwritHomeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MoonwritConfiguration.self,
            provider: MoonwritProvider()
        ) { entry in
            HomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Your line")
        .description("The line you're writing, tonight's moon, and where you are in the nine.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Lock Screen
//
// These are ordinary widgets — permanent, no "go live", no expiry. The thing
// that expires after a few hours is a Live Activity, which is a different
// feature entirely.
//
// Lock Screen widgets are always rendered monochrome by the system, so the
// theme setting deliberately doesn't apply here — there's nothing to theme.

struct LockWidgetView: View {
    let entry: MoonwritEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: moonSymbol)
                        .font(.system(size: 13, weight: .medium))
                    Text("\(entry.snapshot.repsToday)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
            .containerBackground(for: .widget) { Color.clear }

        case .accessoryInline:
            Label(
                entry.snapshot.hasLine ? entry.snapshot.line : "Write your line",
                systemImage: moonSymbol
            )
            .containerBackground(for: .widget) { Color.clear }

        default:
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: moonSymbol)
                        .font(.system(size: 11, weight: .medium))
                    Text("\(entry.snapshot.repsToday) of \(entry.snapshot.repsTarget)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .widgetAccentable()

                Text(entry.snapshot.hasLine ? entry.snapshot.line : "Write your line.")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color.clear }
        }
    }

    /// The system moon glyphs track the real phases, so the lock screen shows
    /// tonight's moon even in monochrome.
    private var moonSymbol: String {
        switch entry.moon.phase {
        case .newMoon:        return "moonphase.new.moon"
        case .waxingCrescent: return "moonphase.waxing.crescent"
        case .firstQuarter:   return "moonphase.first.quarter"
        case .waxingGibbous:  return "moonphase.waxing.gibbous"
        case .fullMoon:       return "moonphase.full.moon"
        case .waningGibbous:  return "moonphase.waning.gibbous"
        case .lastQuarter:    return "moonphase.last.quarter"
        case .waningCrescent: return "moonphase.waning.crescent"
        }
    }
}

struct MoonwritLockWidget: Widget {
    let kind = "MoonwritLockWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MoonwritConfiguration.self,
            provider: MoonwritProvider()
        ) { entry in
            LockWidgetView(entry: entry)
        }
        .configurationDisplayName("Your line")
        .description("Your line and tonight's moon, on the lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Bundle

@main
struct MoonwritWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoonwritHomeWidget()
        MoonwritLockWidget()
    }
}
