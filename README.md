# Lumen

An iOS manifestation app. SwiftUI, no backend, no account, nothing leaves the phone.

Open `Lumen.xcodeproj` in Xcode, pick a simulator or your own device, press ⌘R.

---

## The idea

Most manifestation apps are affirmation wallpaper — a nice quote in the morning
and nothing else. Lumen is built around the bit that actually does the work:
**writing it down, over and over, until you believe it — and then keeping
receipts.**

Three parts, and the app is shaped around them:

**1. Write it down.** One line, present tense, as though it has already
happened. Not "I will have", but "I have". The editor nudges toward this and
refuses to be a to-do list.

**2. Say it until it's boring.** The 3-6-9 method: three repetitions in the
morning, six in the middle of the day, nine at night. In Lumen you *type it
out in full* every single time. Typing is slower than reading, it occupies the
hands and the eyes, and it is very hard to do while thinking about something
else. That is the entire mechanism — the "brainwashing" part, done deliberately.

**3. Write down what shows up.** The Evidence log. Every sign, coincidence,
nudge and small win goes in. On the days you don't believe any of it, this is
the pile you read. This is the part every other app skips, and it's the one
that builds actual trust — because it turns "the universe is listening" from a
feeling into a list you can count.

---

## What's in it

| Screen | What it does |
|---|---|
| **Today** | Greeting, today's 3-6-9 progress ring, one-tap start on the next window, the day's line, quick capture, your numbers |
| **Ritual** | The full-screen writing session. Words light up gold as you type them correctly, a breath ring paces you, haptics on each completed rep, a seal at the end |
| **Intentions** | Everything written down, split into *in motion* and *received*. Each one accumulates charge from repetitions |
| **Evidence** | The proof pile, filterable by kind — sign, synchronicity, nudge, win, received |
| **Scripting** | Journalling from a date that hasn't happened yet, in the past tense, with rotating prompts |
| **Settings** | Your name, the three ritual hours, notifications, haptics, calm motion, accessibility |

### The charge system

Repetitions accumulate per intention, and it tiers up as they do:

| Reps | Tier |
|---|---|
| 0 | Seeded |
| 33 | Anchored |
| 99 | Magnetised |
| 369 | Inevitable |

Nothing is ever taken away. The alignment meter on Today only goes up — this is
a practice, not a productivity app, and a bad week shouldn't punish you.

### Notifications

Three local notifications a day, at hours you choose, carrying **your own
focus line** back to you rather than generic filler. Off by default, and they
never leave the device.

---

## Project layout

```
Lumen/
  LumenApp.swift          entry point, UIKit bar appearance
  Previews.swift          every screen as an Xcode canvas preview
  Core/
    Models.swift          Intention, EvidenceEntry, ScriptEntry, RitualRecord, Profile
    ManifestStore.swift   the single @Observable store + JSON persistence
    Library.swift         all written copy — daily lines, prompts, starters
    Haptics.swift         feedback, respects the settings toggle
    Whispers.swift        local notification scheduling
    Sample.swift          fake data for previews (DEBUG only)
  Design/
    Theme.swift           palette, gradients, type scale, metrics
    Components.swift      cards, chips, rings, buttons, FlowLayout
    CosmicBackground.swift starfield + aurora
  Features/
    RootView.swift        tab navigation
    Onboarding/ Today/ Intentions/ Ritual/ Evidence/ Scripting/ Settings/
```

The project uses Xcode's **file-system synchronised groups**, so adding a new
Swift file is just dropping it into the folder — there is no file list in the
project to keep in sync. Requires **Xcode 16 or newer**.

### Storage

Everything is one `Codable` blob written atomically to Application Support,
debounced by 400ms and flushed on backgrounding. Every model decodes leniently
(missing keys fall back to defaults), so adding a field later won't wipe
somebody's practice.

When it's time for iCloud sync, `ManifestStore.swift` is the only file that
has to change.

---

## Things you'll probably want to change first

**The name.** It's `Lumen` in three places: the folder name, `PRODUCT_BUNDLE_IDENTIFIER`
and `INFOPLIST_KEY_CFBundleDisplayName` in the project's build settings, and
the wordmark in `OnboardingView.welcome` / `SettingsView.aboutSection`.

**The voice.** Every line of copy is in `Core/Library.swift` — daily lines,
seal lines, scripting prompts, starter affirmations, the writing rules. Rewrite
it in your own words; that's the file to hand someone who isn't a developer.

**The palette.** `Design/Theme.swift`. Currently deep indigo night with warm
gold. Change `Palette` and the whole app follows.

**Signing.** Set your team in Signing & Capabilities before running on a real
device.

---

## Where it could go next

Rough order of value, not effort:

1. **Vision board** — images per intention, a proper collage view. This is the
   most-requested feature in every app of this kind and it's missing here.
2. **Audio** — record the affirmation in your own voice, play it back on a
   loop. Your own voice is far more effective than reading.
3. **iCloud sync + a widget** — the lock screen widget showing today's line is
   probably worth more than any in-app screen.
4. **Streak-safe reminders** — a gentle "you're two reps off" late-evening nudge.
5. **Evidence prompts** — a weekly "what showed up this week?" that makes the
   proof pile fill itself.
6. **Export** — a printable year-in-review of everything received. This is the
   thing people would actually pay for.
7. **Share cards** — a beautifully typeset "received" card to post. Free growth.
