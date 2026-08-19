# SESSION HANDOFF — 2026-08-19-a

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-18-a.md`.

## What happened this session

**Phase 0 shipped and is verified on the Mac.** Dictdotclick builds, launches, and lives in the menu
bar. First real application milestone.

**The Xcode wizard was removed from the workflow entirely.** Philip couldn't get through the
five-step walkthrough in the old `scaffold/HOW-TO-USE.md` — the first symptom was Terminal commands
(`cd`, `git pull`, `open`) pasted into a Swift file, with Xcode reporting "Cannot find 'cd' in
scope." Rather than rewriting the instructions, `Dictdotclick.xcodeproj` was authored here and
committed. His workflow is now permanently `git pull` → ⌘R (`RUN-IT.md`).

This is safe because of **file-system-synchronized groups** (Xcode 16+): the project references the
`Dictdotclick/` folder instead of enumerating files. `CLAUDE.md`'s warning about hand-edited
`project.pbxproj` predates that feature. Future phases add `.swift` files with **no project-file
edits at all** — the most fragile recurring step in this project is gone.

**A diagnostic mistake worth remembering.** A check for whether the `.xcodeproj` on his Mac was the
committed one or the wizard's grepped for `PBXFileSystemSynchronizedRootGroup` and reported "MINE."
That test was invalid — modern Xcode generates synchronized-folder projects too. The real evidence
was `Assets.xcassets`, `ContentView.swift`, branch `main`, and one commit named "Initial Commit": a
local repo Xcode had made, unrelated to GitHub. Resolved by renaming his wizard project to
`Dictdotclick-wizard-backup` and cloning fresh.

**One real bug, found and fixed.** First build failed with `Multiple commands produce
.../DerivedData/...`. Cause: seven `.gitkeep` placeholders (one per empty phase folder) — identical
filenames all resolving to the same destination in the app bundle. Synchronized folders sweep up
every file, not just `.swift`. Placeholders and empty folders removed; rule recorded in
`BUILD-SPEC.md`. This was pushed as an explicit hypothesis and confirmed only by the next build.

**`/ddcc` ran for real for the first time**, which cleared its own verification items.

## Needs verifying on the Mac

**Nothing outstanding.** Phases 0 and 1 are both confirmed on the Mac as of 2026-08-19:

- [x] Dock icon and ⌘-Tab absence — neither appears. Decision 7 satisfied.
- [x] Phase 1 builds at `MACOSX_DEPLOYMENT_TARGET = 26.0`.
- [x] `.glassEffect` compiles and renders. The Liquid Glass material pipeline works, so Phase 4's
      floating HUD can rely on it.
- [x] Settings window: four sidebar rows that stay visible at every window size, title bar showing
      the pane title and subtitle, window resizes freely.

No uncompiled Swift exists.

## Gotchas / things to watch for

- **Nothing non-source goes inside `Dictdotclick/`.** Synchronized folders compile/copy everything
  in there. No same-named files at any depth (that's what `.gitkeep` × 7 did), and no notes,
  fixtures, or scratch files. Those live outside the folder.
- **Don't pre-create empty phase folders.** Create a folder when its first real file exists. The
  `App/`, `UI/`, `Hotkey/`… structure in `BUILD-SPEC.md` is a naming convention, not a directory
  tree to lay out in advance.
- **`Dictdotclick-wizard-backup` still exists on Philip's Mac** at
  `~/Documents/Claude/Projects/Dictdotclick/`. Harmless, never pushed anywhere, deletable whenever.
  Worth knowing so a future session doesn't mistake it for the real project.
- **`ContentView.swift` should never appear in this repo.** If it does, someone ran the wizard
  again. There is no `ContentView` in this app — `DictdotclickApp.swift` is the entry point.
- **Stale Xcode errors survive a project switch.** Nine `ContentView.swift` errors persisted after
  cloning the new project and were pure noise. `rm -rf ~/Library/Developer/Xcode/DerivedData` clears
  them. Worth reaching for early when errors reference files that don't exist.
- **`xcodebuild` from Terminal beats reading Xcode's issue navigator** when reporting a failure back
  to a session — Xcode truncates paths (`DerivedData/D...`), the CLI prints them whole.

- **`git rev-parse --show-toplevel` only works from inside the repo.** Handing it to Philip in a
  freshly-opened Terminal (which starts at `~`) silently no-ops the whole command block — every git
  line fails with `not a git repository` and he keeps testing a stale build. Use the absolute path:
  `cd ~/Documents/Claude/Projects/Dictdotclick/Dictdotclick`.
- **The repo root contains a folder with the same name.** `Dictdotclick/Dictdotclick/` holds the
  Swift source; `.xcodeproj` sits in the outer one. One `cd Dictdotclick` too many lands in the
  source folder, where `git` still works but `open Dictdotclick.xcodeproj` does not.
- **Never launch the built `.app` directly.** An instance started with `open .../Dictdotclick.app`
  escapes Xcode's control, so Stop and the Replace prompt don't touch it and the menu bar ends up
  with two mic icons. Launch with ⌘R only; `killall Dictdotclick` is the reset.
- **At the Replace/Add prompt, always Replace.** "Add" is the other way to get duplicate icons.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and in sync with `origin`. `main` untouched. No open PRs.
- **Working tree:** clean.
- **Next step: Phase 1** — the real Settings window. Liquid Glass, sidebar tabs (General / Hotkey /
  Dictionary / History), replacing `SettingsPlaceholderView`. macOS 26 confirmed, so no
  `.ultraThinMaterial` fallback needs building.
- **`DEFERRED.md` was updated this run**, contrary to this skill's usual check-only rule for that
  file: it still claimed Xcode was downloading and the project unbuilt, both false as of tonight.
  Corrected rather than flagged, since leaving known-wrong docs is the drift the handoff exists to
  prevent.
- **Remaining open questions** (in `DEFERRED.md`): preferred default hotkey, needed by Phase 3.
- **Deployment target is macOS 14.0 and Swift 5**, chosen to maximize first-build success. Phase 1
  may want to raise the target to 26.0 for Liquid Glass rather than gating with
  `#available(macOS 26, *)` — a real decision to make, not an oversight.
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
