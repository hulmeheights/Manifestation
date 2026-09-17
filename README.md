# Moonwrit

A manifestation app built on the 3-6-9 practice and the 29-day lunar cycle.
Write one sentence about your life as though it has already happened — three
times in the morning, six in the afternoon, nine at night — then go and act
like the person it describes, and log what turns up.

Open `Moonwrit.xcodeproj`, set your team once (see `SETUP.md`), press ⌘R.
iOS 17+, iPhone.

## What's in it

**Write** — the line in the light, the three windows, and the typing itself.
You type it out rather than tapping a counter; the words you get right take a
highlighter wash as you go.

**See** — visualisation with no timer. A clock counts up, you move on when
you're ready.

**Become** — the other half of the practice. You name who you're becoming, the
app pulls that into concrete acts you can do today, and counts votes rather
than streaks. `BecomingIdea.swift` has the long version of why impersonating
never holds.

**Cycle** — what tonight's moon is for, when the next night worth turning up
for is, and the six-stage map of the month. All computed offline; eclipses
come from a bundled table because they can't be derived without an ephemeris.

**Proof** — the evidence log, and the chapter read-back you can open any time.

**You** — appearance, app icon, notifications, the lock screen card, the three
windows, and your backup.

Plus a widget extension: home screen and lock screen widgets, and a Live
Activity you push live from inside the app.

## Layout

```
Moonwrit/          the app
  Core/            models, store, moon maths, notifications, becoming
  Features/        Onboarding/, Screens/
  Assets.xcassets  both app icons
Shared/            compiled into BOTH the app and the widget
MoonwritWidget/    the widget extension
Support/           entitlements and partial Info.plists
```

`Moonwrit/` and `Shared/` and `MoonwritWidget/` are Xcode file-system
synchronised groups — a new `.swift` file dropped in joins the right target on
its own.

## Everything else

`SETUP.md` covers signing, the three different lock screen things, what iOS
actually allows a notification to look like, and the backup.
