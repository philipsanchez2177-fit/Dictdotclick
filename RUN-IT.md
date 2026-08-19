# How to run Dictdotclick on your Mac

There is no setup wizard to work through. The Xcode project is already built and committed. You open
it and press one button.

---

## Before you start

You need **Xcode** installed (free, Mac App Store, ~10 GB). Open it once after installing and accept
the license prompt — Xcode won't build anything until you do.

---

## Step 1 — get the code

In Terminal:

```
git clone https://github.com/philipsanchez2177-fit/Dictdotclick.git
cd Dictdotclick
git checkout claude/init-ayj2tg
```

If you already cloned it before, just pull the latest instead:

```
cd Dictdotclick
git checkout claude/init-ayj2tg
git pull
```

## Step 2 — open and run

```
open Dictdotclick.xcodeproj
```

Then press **⌘R** (Command-R). That's Run — it compiles the app and launches it.

The first run takes a minute or two. After that it's a few seconds.

---

## What success looks like

- A **microphone icon** appears in your menu bar, top-right
- **No Dock icon**, no window on screen — the app lives only in the menu bar
- Clicking the microphone opens a small menu: **Settings…** and **Quit Dictdotclick**
- **Settings…** opens a placeholder window that says "Settings arrive in Phase 1"
- **Quit** removes the icon
- Pressing **⌘-Tab** does *not* list Dictdotclick

That's the whole of Phase 0. The app does nothing useful yet — that's the point. It proves the
toolchain works end to end before any real feature depends on it.

---

## If something goes wrong

**Don't try to fix it in Xcode.** Copy the error text and paste it into the next Claude session. That
loop is the expected workflow for this project, not a setback — Claude can't compile Swift, so build
errors are how the two halves of this project talk to each other.

Two you might hit, and what they mean:

| What you see | What it means |
|---|---|
| "Signing for Dictdotclick requires a development team" | Click the project name in the left sidebar → **Signing & Capabilities** → set **Team** to your personal Apple ID. Free, no paid account needed. |
| Anything mentioning a deployment target or SDK | The project targets macOS 14 to stay compatible. If Xcode objects, paste the message — it's a one-line fix. |

---

## What you never have to do

Worth stating, because it's the part that was hard before:

- You don't create the project — it exists
- You don't add files to it — the project reads the `Dictdotclick/` folder directly, so any `.swift`
  file that lands there is picked up automatically
- You don't set Info.plist keys — the menu-bar-only setting and the microphone permission text are
  already in the project

Future phases will add Swift files to that folder. Your loop stays the same forever: `git pull`, then
**⌘R**.
