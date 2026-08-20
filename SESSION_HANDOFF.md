# SESSION HANDOFF — 2026-08-19-b

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-19-a.md`.

## What happened this session

**Phase 1 shipped and is verified on the Mac.** The app has a real Settings window: fixed sidebar
(General / Hotkey / Dictionary / History), detail pane with the tab's title and subtitle in the
window title bar, and a Liquid Glass card per pane naming the phase that fills it in. Skeleton only
— no working controls, by design.

Seven new files in `Dictdotclick/UI/Settings/`, picked up automatically by the synchronized folder
with **no `project.pbxproj` edits**. That promise from Phase 0 held.

**Two unknowns cleared, both of which Phase 4 depended on.** `.glassEffect` compiles and renders, so
the Liquid Glass pipeline works and the floating recording HUD can rely on it. And the deployment
target was raised **14.0 → 26.0**, which builds clean. That was a real decision, not a detail:
Liquid Glass is macOS 26-only, and the alternative was gating every use behind `#available` and
maintaining a second visual path for users who don't exist. Revisit only if the app ships beyond
Philip's Mac.

**Four rebuilds, one cause.** `NavigationSplitView` broke the sidebar three separate times — empty
inside the `Settings` scene, then empty again on resize after moving to a `Window` scene. It adapts
its columns to available space on its own, which is right for a navigation hierarchy and wrong for
four fixed rows. The first diagnosis blamed the `Settings` scene and *appeared* to work, which is
why it survived two more rounds. The window is now a plain `HStack` with a fixed-width
`List(.sidebar)` — no negotiation, no collapse, identical layout at every size.

Five layout rules from this went into `BUILD-SPEC.md`, since Phase 2 builds another window.

**Philip cleared Xcode's "Update to recommended settings" warning** and pushed the result (`63a016e`)
— ~16 extra `CLANG_WARN_*` flags, dead-code stripping, and `LastUpgradeCheck` bumped to Xcode 26.
Reviewed here: nothing behavioural. Xcode also reformatted one block of `project.pbxproj`, which
incidentally confirms the hand-authored file parses cleanly.

**The `Dictdotclick-wizard-backup` folder was deleted** from Philip's Mac. Gone from the gotchas.

## Needs verifying on the Mac

**Nothing outstanding.**

**Confirmed as of 2026-08-19:**

- [x] No Dock icon, not in ⌘-Tab. Decision 7 satisfied.
- [x] Builds at `MACOSX_DEPLOYMENT_TARGET = 26.0`.
- [x] `.glassEffect` compiles and renders.
- [x] Settings window: four sidebar rows that stay visible at every size, title bar showing pane
      title and subtitle, window resizes freely down to ~700×440.
- [x] Permissions window opens from the menu bar, reads both permissions correctly, renders its
      glass cards, and shows the "You're all set" state with green badges.
- [x] **Every Phase 2 path, including the ungranted ones.** Confirmed by walking a permission from
      scratch: Allow… showed macOS's own microphone prompt; Open Settings landed directly on
      Privacy & Security → Accessibility; toggling the switch (with an admin password) turned the
      badge green **without any interaction in the app**. That last part confirms the polling — the
      thing that stops the window looking broken after a grant made in another app.
- [x] **Apple's System Settings deep-link URLs are correct on macOS 26.** The
      `x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_*` form works.
      Undocumented and version-sensitive, so this is worth re-checking after a macOS upgrade;
      `Permission.systemSettingsURL` is the one place to change it.

No uncompiled Swift exists in the repo.

## Gotchas / things to watch for

- **Don't use `NavigationSplitView` for fixed panes.** It cost three rebuilds. Reach for it only
  where the sidebar is genuinely a navigation stack. Full rule set in `BUILD-SPEC.md`.
- **A change that makes a symptom disappear is not proof of the cause.** Moving off the `Settings`
  scene produced a working sidebar and hid the real bug for two more rounds. Only the recurrence
  told them apart.
- **Never hand Philip `git rev-parse --show-toplevel`.** It only works from inside the repo, so in a
  freshly-opened Terminal (which starts at `~`) it fails and silently no-ops every git command
  chained behind it — including the `git pull`. Two rounds were lost testing a build that predated
  the fixes. Use the absolute path:
  `cd ~/Documents/Claude/Projects/Dictdotclick/Dictdotclick`.
- **The repo root contains a folder with the same name.** `Dictdotclick/Dictdotclick/` holds the
  Swift source; `.xcodeproj` sits in the outer one. One `cd Dictdotclick` too many lands in the
  source folder, where git still works but `open Dictdotclick.xcodeproj` does not.
- **Never launch the built `.app` directly.** An instance started with `open .../Dictdotclick.app`
  escapes Xcode's control — Stop and the Replace prompt don't touch it — and the menu bar ends up
  with two mic icons. Launch with ⌘R only. `killall Dictdotclick` is the reset.
- **At Xcode's Replace/Add prompt, always Replace.** "Add" is the other route to duplicate icons.
- **When a fix "doesn't work," confirm it's actually on the Mac before re-diagnosing.**

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and in sync with `origin`. `main` untouched. No open PRs.
- **Working tree:** clean. Nothing left uncommitted.
- **Next step: Phase 2** — the permissions walkthrough (Microphone + Accessibility) with live status
  and a System Settings deep link. Sequenced early because permissions are where users of this kind
  of app give up. It builds a second window, so the `BUILD-SPEC.md` layout rules apply directly.
- **`BUILD-SPEC.md` was updated this session** — Phase 1 marked done, deployment target row
  rewritten, and a new "Settings window layout" section added. It is current, not stale.
- **`DEFERRED.md` was not changed** — nothing this session touched its territory. Still current.
- **Remaining open question:** preferred default hotkey, needed by Phase 3.
- **`SWIFT_VERSION` is still 5.0.** Untouched and not yet worth revisiting.
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
