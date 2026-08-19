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

- [x] **Dock icon absence / ⌘-Tab absence.** Confirmed 2026-08-19 — no Dock icon, not in ⌘-Tab.
      Decision 7 satisfied.

**Phase 1 — written, not compiled.** Seven new Swift files plus one edit and one project-file
change. `git pull` → ⌘R, then:

- [ ] **It builds.** `MACOSX_DEPLOYMENT_TARGET` was raised 14.0 → 26.0 in `project.pbxproj` (a
      one-value `sed`, no structural edit). If Xcode complains the SDK can't target 26.0, that's
      the thing to report.
- [ ] **Settings opens with a sidebar.** Menu bar icon → Settings… (or ⌘,). Expect a ~780×520
      window: sidebar listing General / Hotkey / Dictionary / History, detail pane on the right
      with a title, a one-line subtitle, and a card.
- [ ] **Liquid Glass is actually rendering.** The card in each pane and the "Arrives in Phase N"
      pill use `.glassEffect(.regular, in:)`. They should look like frosted, light-bending glass —
      not flat grey boxes. This is the smoke test for the whole material pipeline; Phase 4's
      recording HUD depends on it. If `.glassEffect` doesn't compile, report the exact error — the
      API name is the most likely thing to be wrong, since it can't be checked in the container.
- [ ] **Switching tabs works** and each pane names a different phase (6 / 3 / 7 / 9).
- [ ] **The old placeholder is gone.** No "Settings arrive in Phase 1." text anywhere.

New files, all uncompiled:
`Dictdotclick/UI/Settings/` — `SettingsWindow.swift`, `SettingsTab.swift`, `PhasePlaceholder.swift`,
`GeneralSettingsView.swift`, `HotkeySettingsView.swift`, `DictionarySettingsView.swift`,
`HistorySettingsView.swift`. Plus `Dictdotclick/App/DictdotclickApp.swift` (rewritten) and
`Dictdotclick.xcodeproj/project.pbxproj` (deployment target only).

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
