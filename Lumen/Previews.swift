//
//  Previews.swift
//  Lumen
//
//  Canvas targets for every screen. Open this file in Xcode and flip between
//  them rather than hunting through the feature folders.
//

#if DEBUG
import SwiftUI

#Preview("Today") {
    RootView()
        .environment(Sample.store())
}

#Preview("Today — empty") {
    TodayView()
        .environment(Sample.emptyStore())
}

#Preview("Ritual — night, 9×") {
    RitualView(intention: Sample.focusIntention, window: .night)
        .environment(Sample.store())
}

#Preview("Ritual — morning, 3×") {
    RitualView(intention: Sample.focusIntention, window: .morning)
        .environment(Sample.store())
}

#Preview("Intentions") {
    IntentionsView()
        .environment(Sample.store())
}

#Preview("Intention detail") {
    NavigationStack {
        IntentionDetailView(intentionID: Sample.focusIntention.id)
    }
    .environment(Sample.store())
}

#Preview("Intention editor") {
    IntentionEditorView(existing: nil)
        .environment(Sample.store())
}

#Preview("Evidence") {
    EvidenceView()
        .environment(Sample.store())
}

#Preview("Evidence composer") {
    EvidenceComposer()
        .environment(Sample.store())
}

#Preview("Scripting") {
    ScriptingView()
        .environment(Sample.store())
}

#Preview("Script editor") {
    ScriptEditorView(existing: nil)
        .environment(Sample.store())
}

#Preview("Settings") {
    SettingsView()
        .environment(Sample.store())
}

#Preview("Onboarding") {
    OnboardingView()
        .environment(Sample.emptyStore())
}
#endif
