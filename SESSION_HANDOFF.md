# SESSION HANDOFF — 2026-08-22-b

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-22-a.md`.

## What happened this session

**Phase 6 shipped and is verified. The core loop is complete.** Press the hotkey, talk, press again,
and the transcript is pasted where the cursor already was.

**Both open questions were closed first, at Philip's request.** That turned out to be the valuable
part of the session.

- **The signing doc was wrong and is now decided rather than patched.** `BUILD-SPEC.md` claimed the
  code-signing identity stayed out of the repo; Xcode had written `DEVELOPMENT_TEAM` into
  `project.pbxproj` two sessions earlier. Keeping it committed is deliberate — a fresh clone then
  builds and signs with no Xcode setup, and a wrong signature is exactly what silently revokes
  Accessibility. A Team ID is an account identifier, not a credential.
- **Vocabulary hints are supported.** This was the one open risk in dropping whisper.cpp.
  `AnalysisContext.contextualStrings` takes the word list, `SpeechAnalyzer.setContext` applies it.
  Found by grepping the SDK's own `.swiftinterface`, the same technique that fixed the Phase 5 build
  errors. `AppleTranscriber` now passes hints through and reports `supportsVocabularyHints = true`,
  which had been false only because it was unproven. Decision 4 stands; whisper.cpp stays retired.

**Phase 6 — delivery.** ⌘V rather than synthesised characters: a normal dictation is hundreds of key
events, visibly slow, with dropped characters a known failure at that volume. Pasting's usual
objection — clobbering the clipboard — does not apply, because decision 2 already required the copy.
The clipboard write happens first and unconditionally, so a downstream failure still leaves the user
their words.

**One trap caught before it bit.** The app watches the keyboard and was about to start posting
keystrokes. A transcript containing a backtick, pasted while the binding is a backtick gesture, would
have re-triggered dictation mid-paste. Every posted event now carries `HotkeyMonitor.syntheticMarker`,
which the tap already knew to pass through — the mechanism existed from Phase 3 and only needed
sharing.

**A test that could not have passed, and what it revealed.** The written instructions asked Philip to
dictate into a password field and expect a "copied instead" toast. Secure input does not only block
apps *writing* keystrokes — it blocks them *reading*. With a password field focused the event tap
receives nothing, the hotkey never arrives, and dictation cannot be started there at all. macOS
closes the door rather than letting the app knock. The fallback keeps a narrower reachable case:
secure input switching on mid-dictation.

## Needs verifying on the Mac

**Nothing outstanding.** No uncompiled Swift exists in the repo.

Confirmed 2026-08-22:

- [x] Dictation into TextEdit: hotkey, speech, transcript pasted at the cursor.
- [x] `AnalysisContext.contextualStrings` and `SpeechAnalyzer.setContext` compile as written.
- [x] Dictation cannot be started while a password field has focus — expected, and now documented.

Optional and unreached, low value: the mid-dictation secure-input toast. Start in TextEdit, click
into a password field while recording, then press the hotkey to stop. Expect a glass toast saying
copied — press ⌘V. Worst case if it is wrong: the user presses ⌘V, which the toast says anyway.

## Gotchas / things to watch for

- **Secure input blocks reading, not just writing.** If the hotkey ever appears dead for no reason,
  check whether a password field has focus somewhere — including in a background app that left
  secure input on. That is macOS, not this app.
- **Every keystroke this app posts must carry `HotkeyMonitor.syntheticMarker`.** Anything future that
  synthesises input — Phase 7's snippets, any auto-correction — has to do the same, or the app can
  trigger its own hotkey.
- **`supportsVocabularyHints = true` means the hints are passed, not that they measurably help.**
  Phase 7 tests the effect with a real rare word. Do not upgrade that claim without evidence.
- Earlier gotchas still hold: never paste a fenced code block into Terminal; read the SDK rather than
  guessing a symbol name twice; Team must stay set in Signing & Capabilities; nothing non-source
  inside `Dictdotclick/`.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and in sync with `origin`. `main` untouched. No open PRs.
- **Working tree:** clean.
- **Next step: Phase 7** — the dictionary. Two entry types that run at opposite ends of the pipeline:
  *vocabulary hints* fed to the engine before transcription (plumbing already in, `hints` is
  currently passed as an empty array from `DictationController.transcribe`), and *snippets* applied
  as find-and-replace after it. A snippet trigger must also be registered as a vocabulary hint, or a
  phrase heard wrong can never be replaced. Also the light filler-word cleanup toggle.
- **`BUILD-SPEC.md` and `DEFERRED.md` are current.** BUILD-SPEC gained the paste-vs-type reasoning,
  the secure-input finding, the signing decision, and the resolved hints question. DEFERRED's
  "unverified" section is now "answered", with `SFCustomLanguageModelData` and `DictationTranscriber`
  moved to "worth reaching for later".
- **No open questions.**
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
