# Widgets, the lock screen, and notifications

All three are built and wired into `Lumen.xcodeproj`. There is nothing to add
in Xcode. Open the project, hit ⌘R, and the widget extension builds and
installs alongside the app automatically.

---

## What now exists

There are **three different things**, and they are genuinely different
features in iOS. It's worth knowing which is which, because they behave
differently and people mix them up constantly.

### 1 · Home screen widget — permanent

Long-press an empty part of the home screen → **+** top-left → search
**Moonwrit** → Small or Medium → **Add Widget**.

Long-press the widget afterwards → **Edit Widget** to change:
- **Theme** — match device / Night / Day
- **Show** — your line / tonight's moon / today's reps
- whether the moon is drawn

It updates itself and never expires.

### 2 · Lock screen widget — permanent

Long-press the lock screen → **Customise** → tap the lock screen → tap the
strip under the clock → search **Moonwrit**.

Three shapes: circular (moon + reps ring), rectangular (your line), inline
(one line of text above the clock). Also customisable via Edit Widget.

Once added it is there forever. You never re-add it.

### 3 · Live Activity — the one you push live

**You → Lock screen → Push it live.**

This is the Mononote-style one. It is a full-width card that appears
*immediately* on the lock screen, above everything, and in the Dynamic Island
on the phones that have one. It holds your line and counts your reps up as
you write them.

Things that are true about it, because they're set by iOS and not by us:

- Only the app can start one, and only while it's open on screen. Nothing can
  start one in the background — that's an iOS rule, not a missing feature.
- It survives the app being closed and the phone being locked. That's the
  point of it.
- iOS ends it on its own after about **eight hours** on screen. Writing a rep
  puts it back up, so in practice it lives as long as the practice does.
- Only one at a time. Pushing it live again replaces the old card.
- **You → Lock screen → Take it down** removes it instantly.
- If it says "Blocked in iOS", the switch is at Settings → Moonwrit →
  Live Activities.

---

## Notifications

**You → Notifications.** Allow them once, then:

- **Moon nights** — the new moon, the full moon, supermoons and eclipses,
  with what each one is good for.
- **Your three windows** — morning, afternoon, night, at the hours you set
  further down that screen.
- **Send me one in 5 seconds** — the full-width button. It fires a real
  notification with the current moon drawn as the attachment, so you can see
  exactly what they look like before committing to them.

Two things about how they look, which are iOS's decisions and not ours:

- The small icon on the left of a notification is **always the installed
  build's app icon**. If you changed the icon in the app, notifications keep
  showing the old one until you rebuild and reinstall.
- The layout of a notification is fixed by the system. The only thing an app
  can control visually is the **attachment** — the image on the right. Ours
  is the moon as it is on the night the notification fires, drawn at send
  time. That's why the app schedules fourteen days individually instead of
  one repeating alert: a repeating notification would carry the wrong moon.

---

## If the build fails on signing

The widget and the app share an **App Group**
(`group.com.hulmeheights.lumen`) so the widget can read your line. App Groups
need a **paid** Apple Developer account. On a free personal team, signing will
fail with something about entitlements or provisioning profiles.

Two options:

1. Pay the £79 — you need it for the App Store anyway, and everything works.
2. Temporarily drop the group: in `Lumen.xcodeproj/project.pbxproj`, delete
   the two `CODE_SIGN_ENTITLEMENTS = Support/...entitlements;` lines. The app
   and the Live Activity keep working; the home and lock screen widgets fall
   back to showing the moon and a prompt instead of your line, because
   without the group they genuinely cannot see it.

Paste me the error either way and I'll do it.

---

## Where the code lives

| Folder | Target | What's in it |
|---|---|---|
| `Lumen/` | app only | Everything you see inside the app |
| `Shared/` | **both** | `MoonPhase.swift`, `Moonlight.swift`, `SharedSnapshot.swift`, `MoonwritActivity.swift` |
| `MoonwritWidget/` | widget only | `MoonwritWidgets.swift`, `MoonwritLiveActivity.swift` |
| `Support/` | build settings | entitlements and partial Info.plists for both targets |

Both folders are Xcode *file-system synchronised groups*, so a new `.swift`
file dropped into either one joins the right target on its own. Nothing to
tick, ever.
