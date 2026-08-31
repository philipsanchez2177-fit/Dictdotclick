# SESSION HANDOFF — 2026-08-28-b

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-28-a.md`.

## What happened this session

**Phase 8 shipped and is verified — nine of ten phases done.** Live text preview: the pill now shows
words while you're still talking instead of only after you stop. This was the phase the project
sequenced deliberately last, called out from the very first planning session as the hardest problem —
so it earns its own entry in `docs/BUILD-JOURNAL.md`.

The design centres on one small rule (`LiveTranscript.apply`): the engine marks every result final or
volatile, and reconciling that is "accumulate finals, replace volatile wholesale" — nothing cleverer,
because anything cleverer would be second-guessing an engine that has more information than this code
does. Everything else in the phase exists to protect that rule from the real world:

- **The one-shot path from Phase 5 is the fallback, not replaced.** `AudioCapture` still records the
  full buffer regardless of whether a live session is running. `DictationController` prefers the live
  session's committed text on stop, but falls straight through to a full one-shot transcription if the
  session throws or comes back empty — `try?`, deliberately silent, because a streaming bug should
  degrade a dictation to "slightly slower," never to "failed."
- **A real race was caught and fixed before it ever reached the Mac.** Opening a live session is async
  and takes a moment; the microphone is already recording before it returns. Naively wiring new audio
  to the session would silently drop the first words of every dictation during that setup window.
  `AudioCapture.beginLiveFeed` closes it with one lock covering two things at once — handing back
  everything captured so far *and* starting to route new audio to the session — so nothing lands in
  neither bucket.
- **A second bug was caught the same way, in a file that looks unrelated.** Adding the
  `enableLivePreview` setting meant `AppSettings`'s `Stored` struct gained a field. Synthesized
  `Decodable` treats a missing key on a non-optional property as a decode failure for the *whole*
  struct — which would have silently reset an existing `removeFillerWords` choice back to its default
  the moment someone updated past this point. Rewritten to decode each field independently
  (`decodeIfPresent`) before that could ever bite.

**Verified on the Mac same day.** Build succeeded on the first try — `.progressiveTranscription` and
an unfiltered `transcriber.results` loop were new API surface, guessed from the framework's shape
rather than confirmed the way Phase 5's symbols were, and both held up. Text appeared in the pill live,
matched the delivered transcript, and the toggle correctly fell back to the plain waveform-and-timer
pill when off. One thing that looked like a bug at first and wasn't: a short, unbroken sentence stayed
dimmed the *entire* time and only turned solid right at the end — correct, because the engine finalizes
a whole segment at a pause or at the end of the utterance, not word by word. Worth remembering if it
comes up again; a longer dictation with natural pauses should show it finalizing in visible chunks.

**Finding the actual project folder took most of the debugging time, not the code.** Philip's live
Xcode project isn't at the path this skill's own instructions might suggest — it's nested one level
deeper, at `~/Documents/Claude/Projects/Dictdotclick/Dictdotclick` (the outer `Dictdotclick` folder is
a separate Cowork-synced folder, not a git clone). Worth remembering for next time so this doesn't cost
another round of `find` commands.

## Needs verifying on the Mac

**Nothing outstanding from Phase 8's core functionality** — build, live text, delivery match, and the
toggle are all confirmed above.

Two items carried from Phase 8 as "believed safe by design" were closed out by code audit rather
than a Mac test — reading the actual control flow line by line rather than trusting the comment
describing it:

- [x] **The short-dictation race.** Traced `startListening` → `stopListening` end to end. If stop
      fires before `makeLiveSession` returns, `liveSession` is still `nil` at that point, so
      `finishDictation` gets `nil` and falls back to one-shot transcription over the full buffer
      `AudioCapture.stop()` already captured — no audio is lost. When the delayed setup task resumes,
      its `Task.isCancelled` check catches the cancellation, closes the session it just opened, and
      returns without ever calling `beginLiveFeed`. `endLiveFeed()` is confirmed a safe no-op when the
      handler was never registered. No test needed; the logic cannot lose a word in this window.
- [x] **Old `settings.json` decoding.** Confirmed `AppSettings.Stored.init(from:)` decodes each field
      independently via `decodeIfPresent(...) ?? default`, so a file missing `enableLivePreview`
      (written before Phase 8) still decodes `removeFillerWords` from what's actually on disk — the
      failure mode a synthesized decoder would have (one missing key resets the whole struct) does
      not apply here.

Neither required running the app; both were provably correct from the code alone.

Confirmed 2026-08-28: `Dictdotclick.xcodeproj` builds clean with all of Phase 8's new and changed
files; the pill shows live text while dictating; delivered text matches what the pill showed; the
live-preview toggle correctly switches the pill between the old and new look with no size change.

Confirmed earlier and still true: snippets expand in real use and the dictionary persists across
relaunch; the locked-row editor reads as committed; dictation into TextEdit pastes at the cursor;
`contextualStrings` and `setContext` compile; dictation cannot start while a password field has focus.

## Gotchas / things to watch for

- **The project's actual location on Philip's Mac** is
  `~/Documents/Claude/Projects/Dictdotclick/Dictdotclick` — one level deeper than the outer
  `Dictdotclick` folder, which is a separate Cowork-synced folder and not the git clone. Point Philip
  there directly rather than re-deriving it with `find` next time.
- **Every failure in the live-preview path is silent by design**, all the way from session-open
  failure to a results-stream error. That was the right call for reliability — a streaming bug must
  never surface as a broken dictation — but it means a future regression in this path would show up
  only as "the pill went quiet," with no `lastIssue`, no log, nothing. If that's ever reported, the
  first place to look is `DictationController.beginLivePreview`'s `catch` block.
- **A struct gaining a field is a decode hazard, not just an addition.** `AppSettings.Stored`'s custom
  `init(from:)` is the pattern going forward — any future field on a `Codable` settings struct should
  use `decodeIfPresent` rather than relying on synthesized decoding, or an old file on disk will reset
  every other field in the same struct back to default the moment it fails to find one new key.
- Earlier gotchas still hold: an editor owes the user a state that visibly is not editable —
  acknowledgement is not closure; porting logic to Python tests the algorithm and never the Swift;
  snippets are where private data lands by design; every posted keystroke needs
  `HotkeyMonitor.syntheticMarker`; secure input blocks reading as well as writing; never paste a
  fenced code block into Terminal; read the SDK rather than guessing a symbol name twice.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and in sync with `origin`. `main` untouched. No open PRs.
- **Working tree:** clean.
- **`BUILD-SPEC.md` and `DEFERRED.md` were both updated this session and are current.** BUILD-SPEC's
  Phase 8 row is marked done and verified; a new decision-record section documents the reconciliation
  rule, the fallback design, the render-thread/backlog handling, and the fixed-size pill row. DEFERRED
  gained a note that live-session vocabulary hints are set once at session start, same rule the
  one-shot path already used.
- **Next step: Phase 9** — transcript history and background vocabulary suggestions with
  approve/dismiss, resting on Phase 7's dictionary storage. Nothing has been designed yet.
- **No open questions.**
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
