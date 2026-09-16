# Moonwrit — setup, and what iOS actually allows

Everything in here is built and wired into `Lumen.xcodeproj`. Open it, set
your team once (below), press ⌘R.

---

## 1 · Signing — the one thing you have to click

Xcode doesn't keep your team in the project file unless it's written there, so
after replacing the project you set it once:

- Blue **Lumen** project → **Lumen** target → **Signing & Capabilities** → **Team**
- Then the **MoonwritWidget** target → same Team

**Send me your Team ID and I'll write it into the project so you never do this
again.** It's the ten characters shown under the Team dropdown, or in
Xcode → Settings → Accounts.

**App Groups need a paid developer account.** The app and widget share one so
the widget can read your line. On a free Apple ID the build fails on
entitlements. Either pay the £79 (you need it for the App Store anyway) or
delete the two `CODE_SIGN_ENTITLEMENTS = Support/…` lines from
`Lumen.xcodeproj/project.pbxproj` — the app and the Live Activity keep
working, and the widgets show the moon and "Open Moonwrit" instead of your
line, because without the group they genuinely can't see it.

---

## 2 · The three lock screen things, which are not the same thing

**Home screen widget** — permanent. Long-press the home screen → **+** →
search Moonwrit → Small or Medium. Long-press it → **Edit Widget** for theme,
what it leads with, and whether the moon shows.

**Lock screen widget** — permanent. Long-press the lock screen → **Customise**
→ tap the lock screen → the strip under the clock → search Moonwrit. Circular,
rectangular and inline. Add once, there forever.

**Live Activity** — the one you push live. **You → Lock screen → Push it
live.** Full-width card on the lock screen and in the Dynamic Island, holding
your line and counting reps up as you write. Take it down from the same place.

What iOS decides, not us: only the app can start one, and only while it's open
on screen. It survives the app closing and the phone locking. iOS ends it
after about eight hours; writing a rep re-arms it. One at a time.

---

## 3 · Notifications

**You → Notifications.** The switches are always there — flipping one on is
what asks iOS for permission.

- **Your line, three times a day** at the hours set further down that screen.
- **Moon nights** — new moons, full moons, supermoons, eclipses.
- **Send me one in 5 seconds** — a real one, so you can see it.

Three things worth knowing, all of them iOS's rules:

1. A notification that fires **while the app is open** is thrown away by iOS
   unless the app installs a delegate saying otherwise. It didn't have one,
   which is why the test button looked dead. `NotificationRelay` is that
   delegate, and it's installed before launch finishes.
2. The **small icon is always the app icon of the installed build**. There is
   no API for it. If it's showing an old one, the build on the phone is
   behind — run it again from Xcode. Deleting the app clears it too, but takes
   your practice with it, so rebuild first.
3. The **layout is the system's**. The only part an app designs is the
   attachment. Ours is now a drawn card — near-black ground, stars, the
   glowing moon, your line in cream — the same face as the Live Activity.
   Pull the banner down to see the whole thing.

Time Sensitive delivery (breaking through a Focus) needs a separate
entitlement from Apple, so these are ordinary notifications. Nothing in the
app claims otherwise.

---

## 4 · Your copy

**You → Your copy → Save a copy.** The whole practice is one JSON file on the
phone and nowhere else — that's the privacy story, but it also means deleting
the app takes every rep with it and there's no server to recover from. Save a
copy into iCloud Drive now and again. **Restore from a copy** reads one back.

---

## 5 · Where the code lives

| Folder | Target | Contents |
|---|---|---|
| `Lumen/` | app | Everything you see inside the app |
| `Shared/` | **both** | `MoonPhase`, `Moonlight`, `SharedSnapshot`, `MoonwritActivity` |
| `MoonwritWidget/` | widget | `MoonwritWidgets`, `MoonwritLiveActivity` |
| `Support/` | build | Entitlements and partial Info.plists |

Both folders are Xcode file-system synchronised groups, so a new `.swift` file
dropped into either joins the right target on its own. Nothing to tick, ever.
