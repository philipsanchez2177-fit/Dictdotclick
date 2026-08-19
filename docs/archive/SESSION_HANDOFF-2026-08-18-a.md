# SESSION HANDOFF — 2026-08-18-a

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.

First session — no prior handoff to archive.

## What happened this session

Dictdotclick was defined and the repo was set up. **No application code was written**, by design —
the session went into deciding what to build before building it.

**The interview.** Six questions, one at a time, each with a recommendation and reasoning. All seven
resulting decisions are recorded in `BUILD-SPEC.md`. Two answers diverged from the recommendation
and both mattered:

- **Live text preview** was added to the recording pill. This moved streaming transcription from a
  nice-to-have into its own phase (Phase 8), sequenced last so a failure there leaves a working app
  behind it.
- **Spoken shorthand** was requested alongside vocabulary hints — saying "my home address" should
  type the real address. These are two different mechanisms at opposite ends of the pipeline
  (prompt-before vs. replace-after), with a dependency: a snippet trigger must also be a vocabulary
  hint, or it can't be heard correctly enough to replace. Documented in `BUILD-SPEC.md`.

The hotkey rule also landed tighter than proposed: **modifier combos and function-row keys only**,
no bare characters. Function keys sidestep the "you can no longer type K" problem entirely, without
needing warning UI.

**The environment constraint.** Claude sessions run on Linux; a SwiftUI app requires Xcode on a Mac.
Code gets written here and can only be proven there. The failure mode — committing Swift, reporting
success, discovering a pile of errors ten phases later — is the thing the rest of this session was
built to prevent.

**`/ddcc` skill built.** `.claude/skills/ddcc/SKILL.md`, modeled on the ORBIT `/calibrate` ritual,
with three project-specific adaptations: it never reports Swift as verified, it maintains a
carried-forward Mac-verification checklist, and it bootstraps the project docs on first run. Lives
inside the repo rather than in the container's home folder so it survives container reclamation and
works anywhere the repo is cloned.

**Docs bootstrapped this run:** `BUILD-SPEC.md`, `DEFERRED.md`, `CLAUDE.md`, `docs/BUILD-JOURNAL.md`
(first entry added — the session earned one on the decision-making and the verification-honesty
mechanism).

## Needs verifying on the Mac

- [x] **`/ddcc` loads as a skill.** Confirmed 2026-08-19 — it appears in the session's skill list, so
      the frontmatter is valid. (It was undiscoverable in the session that created it because skills
      are loaded at session start; that was expected.)
- [ ] **`/ddcc` guardrails are untested.** The repo check (refuse outside Dictdotclick) and the
      branch check (refuse on `main`) are written but have never executed. *Confirm on the first
      real run.*

**Phase 0 — written in the container, never compiled:**

- [x] **The Xcode project opens and builds.** Confirmed 2026-08-19 — `xcodebuild` reported
      `** BUILD SUCCEEDED **` and the app launched with a mic icon in the menu bar. The
      hand-authored `project.pbxproj` and synchronized folders both work.
- [x] **Menu and Settings window.** Confirmed 2026-08-19 — the mic icon opens its menu and
      Settings… brings up the placeholder window in front. `SettingsLink` works in an `LSUIElement`
      app with no `NSApp.activate` workaround, which had been flagged as the likely failure.
- [ ] **Dock icon absence / ⌘-Tab absence.** Not explicitly checked. `LSUIElement` is clearly
      active (no window at launch), so this is expected to pass — just unconfirmed.
- [x] **Synchronized folders sweep up non-source files.** Confirmed the hard way 2026-08-19: seven
      `.gitkeep` placeholders broke the build with `Multiple commands produce`. Placeholders removed;
      rule recorded in `BUILD-SPEC.md`.
- [x] **Signing.** Confirmed 2026-08-19 — "Sign to Run Locally" worked with no Apple ID or team
      configuration needed.

## Gotchas / things to watch for

- **`/calibrate` will refuse in this repo, correctly.** It's hard-scoped to ORBIT — it checks for an
  ORBIT-referencing `CLAUDE.md` and runs `npm run build`. Use `/ddcc` here.
- **The `.gitignore` excludes `Models/`.** Whisper model files are 460 MB–1.5 GB and must never be
  committed. If a model ever shows up in `git status`, something is wrong with the download path.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and tracking `origin`. `main` untouched. No open PRs.
- **Working tree:** clean. Nothing uncommitted, nothing left half-finished.
- **Next step:** install Xcode, then `git pull` and ⌘R (`RUN-IT.md`). Phase 0 finishes the moment a
  mic icon appears in the menu bar.
- **The `scaffold/` folder is gone.** Its wizard walkthrough was replaced by a committed Xcode
  project, so there is no project to create by hand any more — see `RUN-IT.md`.
- **Both blocking questions are answered** (2026-08-19): macOS 26 Tahoe, so full Liquid Glass and no
  fallback path to build; Xcode not yet installed, and that download blocks everything.
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
