# Turning the widgets on

Five minutes, once. The widget code is already written — `LumenWidget/MoonwritWidgets.swift`
— but a widget extension is a **second binary** inside the app, and that has to
be added to the Xcode project by hand. It cannot be done from code, which is why
it's still off.

Do this on the Mac with `Lumen.xcodeproj` open.

---

## 1 · Add the target

1. Menu bar → **File → New → Target…**
2. Search **Widget Extension**. Select it. **Next.**
3. **Product Name:** `MoonwritWidget`
4. **Untick** "Include Live Activity" — we don't want one; lock screen widgets
   are permanent and Live Activities are the ones that expire.
5. **Tick** "Include Configuration App Intent" — that's what makes the widget
   customisable.
6. **Finish.**
7. If it asks "Activate MoonwritWidget scheme?" → **Cancel**. You want to keep
   running the main app, not the widget on its own.

## 2 · Swap in the real code

Xcode will have created a folder called `MoonwritWidget` with three or four
placeholder files.

1. Select every file inside that folder **except** `Info.plist` and the
   `.entitlements` file. Right-click → **Delete → Move to Trash**.
2. In Finder, drag `LumenWidget/MoonwritWidgets.swift` into the
   `MoonwritWidget` group in Xcode's sidebar.
3. In the dialog that appears: **untick** "Copy items if needed", and under
   "Add to targets" **tick MoonwritWidget only** — not Lumen.

## 3 · Share data between them

The widget can't read the app's save file directly. They need a shared box.

1. Select the blue **Lumen** project at the top of the sidebar.
2. Select the **Lumen** target → **Signing & Capabilities** tab.
3. Click **+ Capability** → double-click **App Groups**.
4. Click the **+** under the empty list. Name it:
   `group.com.hulmeheights.lumen`
   (or anything starting `group.`, as long as you use the same one everywhere).
5. Now select the **MoonwritWidget** target → **Signing & Capabilities** →
   **+ Capability** → **App Groups** → tick the *same* group.

If you used a different name, open `Lumen/Core/SharedSnapshot.swift` and change
the `appGroup` constant at the top to match.

## 4 · Let the widget see the shared code

The widget needs three files from the app. This is a checkbox, not a copy.

For **each** of these files — click it in the sidebar, then look at the
**File Inspector** on the right (the ⌥⌘1 panel), find **Target Membership**,
and tick **MoonwritWidget** as well as Lumen:

- `Lumen/Core/MoonPhase.swift`
- `Lumen/Core/SharedSnapshot.swift`
- `Lumen/Design/Moonlight.swift`

## 5 · Run it

Select the **Lumen** scheme and your iPad, then ⌘R as normal.

**Home screen:** long-press an empty bit of home screen → **+** top-left →
search **Moonwrit** → pick Small or Medium → **Add Widget**.
Long-press the widget → **Edit Widget** to change the theme (Match device /
Night / Light), what it leads with, and whether the moon shows.

**Lock screen:** long-press the lock screen → **Customise** → tap the lock
screen thumbnail → tap the area under the clock → search **Moonwrit**.

Both are permanent. There's no "go live" and no expiry — that's Live
Activities, which are a different feature and not what these are.

---

## If something goes wrong

**"No such module 'WidgetKit'"** — the file is in the app target instead of the
widget target. Check Target Membership on `MoonwritWidgets.swift`: it should be
ticked for MoonwritWidget *only*.

**"Cannot find 'MoonPhase' in scope"** — step 4 wasn't done, or one of the three
files was missed.

**Widget shows placeholder text forever** — the App Group names don't match
between the two targets, or don't match `SharedSnapshot.swift`. All three have
to be identical.

**"Invalid redeclaration"** — the Xcode-generated placeholder files weren't
deleted in step 2.
