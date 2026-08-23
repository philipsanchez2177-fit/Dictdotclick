# SESSION HANDOFF — 2026-08-22-a

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-20-a.md`.

## What happened this session

**Phases 4 and 5 shipped and are verified. The app does its core job:** press the hotkey, talk, press
again, and the transcript appears in Settings → General. Typing it into the focused app is Phase 6.

**Phase 4 — microphone and the pill.** `AVAudioEngine` capture converted to 16 kHz mono float on the
way in, so Phase 5 received exactly the format it wanted and the conversion was proven before
anything depended on it. The floating pill is an `NSPanel`, not a SwiftUI `Window` — confirmed on the
Mac that it never takes focus and typing continues underneath it. Waveform tracks the voice, timer
counts, dragged position persists.

**Phase 5 — transcription, and the engine changed.** Philip asked whether macOS already had
speech-to-text built in. It does: macOS 26's `SpeechAnalyzer`. Adopted over whisper.cpp, which
deleted the largest remaining risks — a ~460 MB model download, a C++ dependency that could fail to
build, and a binary that must never reach git. Decision 1 ("on-device, nothing leaves the Mac") is
untouched; it never named an engine, so this was a stack change.

First transcript, from 8.9 seconds: *"I am testing this dictation app. Today is Saturday, August 22nd
at 9:03 PM."* Punctuation, capitalisation, ordinal and clock formatting all correct, no
post-processing, no download.

**Transcription now sits behind a `Transcriber` protocol**, because one requirement is unproven
against this engine: decision 4's vocabulary hints. `AppleTranscriber` reports
`supportsVocabularyHints = false` — unproven, not disproven — and the UI says so in plain text rather
than implying the feature works.

**Two build errors, both in that one file**, both wrong symbol names. Fixed by grepping the SDK's own
`.swiftinterface` rather than guessing twice. That technique is now in `BUILD-SPEC.md`.

**The evening's real cost was git, not code.** A markdown code fence pasted into Terminal left zsh at
a `bquote>` prompt that swallowed a `git pull`; the next build was Phase 4 unchanged, reported as
"Phase 5 looks no different." The handoff's own rule caught it — confirm the code is on the Mac
before re-diagnosing — at the cost of one round instead of several.

## Needs verifying on the Mac

**Nothing outstanding.** No uncompiled Swift exists in the repo.

Confirmed 2026-08-22:

- [x] Pill appears on the hotkey, waveform tracks the voice, timer counts up.
- [x] Clicking the pill does not steal focus; typing continues in the app underneath.
- [x] A dragged pill returns to the same place on the next dictation.
- [x] Speech is transcribed correctly, on-device, with punctuation and no model download.
- [x] `AppleTranscriber` builds against the real macOS 26 Speech API.

Not explicitly checked, low risk: that the pill floats above a full-screen app.

## Gotchas / things to watch for

- **Never paste a fenced code block into Terminal.** The ``` marks are formatting, not command. zsh
  reads the backticks as command substitution, drops to `bquote>`, and eats whatever follows —
  including the `git pull` you thought you ran. Copy only the command line itself.
- **Read the SDK instead of guessing a symbol name twice.** One `grep` over the framework's
  `.swiftinterface` in `$(xcrun --show-sdk-path)` gives ground truth. Full command in `BUILD-SPEC.md`.
- **`pull.rebase false` and `core.editor nano` are now set** on Philip's clone. Before that, a pull
  with divergent branches refused outright, and the merge that followed dropped him into vim with no
  way out. If a future session sees either symptom, the config was lost.
- **Xcode writes `DEVELOPMENT_TEAM` into `project.pbxproj`.** It is now committed, so
  `BUILD-SPEC.md`'s earlier claim that signing stays out of the repo is no longer true — see below.
- Earlier gotchas still hold: Team must stay set or Accessibility silently stops applying; nothing
  non-source inside `Dictdotclick/`; six compile errors often means one real problem.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and in sync with `origin`. `main` untouched. No open PRs.
- **Working tree:** clean.
- **Next step: Phase 6** — auto-type into the focused app plus a clipboard copy (decision 2). Short
  phase: Accessibility is already granted and is the same permission that allows synthetic
  keystrokes. Needs a fallback toast for contexts that refuse them — password fields, some VMs.
  After Phase 6 the core loop is complete and everything remaining is refinement.
- **One doc inconsistency to resolve, flagged not fixed.** `BUILD-SPEC.md` says the signing identity
  is per-machine and not committed. Xcode has since written `DEVELOPMENT_TEAM` into
  `project.pbxproj` and it is committed and pushed. Harmless — a Team ID is not a secret — but the
  document and the repo disagree. Either update the wording or gitignore the setting; pick one early
  in the next session rather than letting it drift.
- **`BUILD-SPEC.md` and `DEFERRED.md` are current.** BUILD-SPEC gained the engine-swap rationale, the
  focus rules for the pill, and the read-the-SDK technique. DEFERRED gained the vocabulary-hints
  question with its fallback order, and `DictationTranscriber` as an alternative worth testing.
- **Open question for Phase 7:** does `SpeechAnalyzer` support vocabulary hints? Everything about
  decision 4 depends on the answer.
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
