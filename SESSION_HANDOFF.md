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

- [ ] **`/ddcc` loads as a skill.** Skills are discovered at session start, so it was not loadable in
      the session that created it — `Skill(ddcc)` returned "Unknown skill," which is expected.
      *Next session: run `/ddcc`. Expect it to load and follow its steps. If it reports unknown, the
      frontmatter needs a look.*
- [ ] **`/ddcc` guardrails are untested.** The repo check (refuse outside Dictdotclick) and the
      branch check (refuse on `main`) are written but have never executed. *Confirm on the first
      real run.*

No Swift exists yet, so nothing is pending a compile.

## Gotchas / things to watch for

- **`/calibrate` will refuse in this repo, correctly.** It's hard-scoped to ORBIT — it checks for an
  ORBIT-referencing `CLAUDE.md` and runs `npm run build`. Use `/ddcc` here.
- **The `.gitignore` excludes `Models/`.** Whisper model files are 460 MB–1.5 GB and must never be
  committed. If a model ever shows up in `git status`, something is wrong with the download path.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and tracking `origin`. `main` untouched. No open PRs.
- **Working tree:** clean. Nothing uncommitted, nothing left half-finished.
- **Next step:** Phase 0 — scaffold the Xcode project so a real app icon appears in the menu bar.
- **Blocking questions for Philip** (in `DEFERRED.md`): what macOS version he's on (Liquid Glass
  needs macOS 26 Tahoe; below that we fall back to `.ultraThinMaterial`), and whether Xcode is
  installed. Nothing can be run without Xcode.
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
