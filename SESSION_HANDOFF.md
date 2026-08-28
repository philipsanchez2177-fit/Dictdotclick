# SESSION HANDOFF — 2026-08-28-a

## Update — Phase 8 written 2026-08-28

**Written, not compiled.** Live text preview for the pill — see `BUILD-SPEC.md`'s new Phase 8
section for the design. Six files touched, one new:

- `Dictdotclick/Transcription/LiveTranscription.swift` — **new.** `LiveTranscript` (the
  final/volatile split and the fold-in rule) and the `StreamingTranscriber` /
  `LiveTranscriptionSession` protocols.
- `Dictdotclick/Transcription/AppleTranscriber.swift` — added `StreamingTranscriber` conformance and
  `AppleLiveSession`, using `.progressiveTranscription` instead of Phase 5's `.transcription`.
- `Dictdotclick/Audio/AudioCapture.swift` — added `beginLiveFeed` / `endLiveFeed`, the atomic
  snapshot-and-subscribe handoff that stops async session setup from losing the first words.
- `Dictdotclick/Hotkey/DictationController.swift` — `startListening`/`stopListening` now run a live
  session alongside the recording; `stopListening` prefers the session's committed text and falls
  back to the untouched one-shot path on any failure or empty result.
- `Dictdotclick/Storage/AppSettings.swift` — new `enableLivePreview` toggle, default on. Decode is
  now hand-written (`decodeIfPresent` per field) rather than synthesized, so a settings.json from
  before this field existed doesn't lose the user's `removeFillerWords` choice on upgrade.
- `Dictdotclick/UI/HUD/RecordingPillView.swift` — a fixed-size second row showing finalized text in
  the normal colour and the engine's current guess dimmed below it.
- `Dictdotclick/UI/Settings/GeneralSettingsView.swift` — the toggle's card.

**Needs verifying on the Mac, added this session** — the prior session's checklist (below, under
"Session — 2026-08-27-a") closed clean; these are the new open items:

- [ ] `Dictdotclick.xcodeproj` still builds with the new file and the changed ones. This is the
  first real test — `SpeechTranscriber(preset: .progressiveTranscription)` and iterating
  `transcriber.results` without a `where isFinal` filter are new API surface, guessed from the
  framework's shape rather than confirmed the way Phase 5's symbols were. If it doesn't compile,
  grep the `.swiftinterface` per the method `BUILD-SPEC.md` already documents rather than guessing
  twice.
- [ ] Say something and watch the pill: does text appear while talking, does the volatile (dimmed)
  tail visibly get replaced as the engine revises itself, and does typing land correctly once you
  stop? That last part is the one that matters most — a live preview that shows the right words but
  delivers something else would be worse than no preview.
- [ ] Turn the pill's "Show text while dictating" toggle off in Settings → General, dictate, confirm
  the pill goes back to exactly the old waveform-and-timer look with no size change.
  Turn it back on.
- [ ] A very short dictation (press, say one word, press again immediately) — this exercises the
  race where `stopListening` can fire before the live session finished opening; should fall back to
  one-shot cleanly, no hang, no crash.
- [ ] Optional, lower priority: pull an old `settings.json` (or just check today's still has your
  filler-word choice, if you'd set one) after this update, to confirm the decode fallback didn't
  reset it.

## Session — 2026-08-27-a (prior)

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-26-a.md`.

## What happened this session

**Phase 7 is verified and closed.** Snippets expand correctly in real use — saying "my address"
types the stored address — and the dictionary survives relaunch. Eight of ten phases done; the
remaining two are refinement.

**The session's work was one complaint, fixed twice.** Entering a word or snippet had no way to
"lock it in": no button, no visible effect from Return. The data was safe — the store saves on every
keystroke — but there was no way to know that without dictating and watching.

**The first fix was the wrong shape.** It kept autosave and added acknowledgement: a green tick per
row once usable, a "Saved" flash on Return, a row count per card. It addressed the words of the
complaint and not the complaint. The reply was precise: *"it just kind of stays live in the window
and the cursor stays in there... there needs to be some way to confirm, yep, that's what I want in
there."*

A tick beside a field with a caret still in it does not read as committed, because the field is still
a field. What was missing was not confirmation — it was **closure**.

**The second fix changed the shape.** Rows now have two states and only one is editable:

| State | Looks like |
|---|---|
| **Locked** (resting) | Plain dimmed text on a tinted background. Not a field. This is what "stored" looks like. |
| **Editing** | Real fields, entered via pencil or click, left via Return or **Done**. |

Nothing about *when* the write happens changed. The interface just stopped pretending a row was open
when it wasn't. Four details fell out of that shape, each fixing something the first pass had wrong:
new rows open in editing (a locked blank row is unfillable); committing an empty row deletes it, so
Return also cancels a row added by mistake; focus is set on the next runloop tick, because the field
does not exist until the view rebuilds; and a snippet's multi-line expansion cannot submit on Return,
so **Done** is its exit.

**Phase 7 closed without the measurement it nominally owed.** Whether vocabulary hints *improve*
recognition was never tested. Philip's call, and the right one: mishearings surface over weeks of real
dictation, not on demand, and a contrived one-word before/after would answer less than actual use.
Recorded honestly rather than marked verified — `DEFERRED.md` carries it as *open over time, not
blocking*, with the event that reopens it.

## Needs verifying on the Mac

**Nothing outstanding.** No uncompiled Swift exists in the repo.

Confirmed 2026-08-27:

- [x] Snippets expand in real use; the dictionary persists across relaunch.
- [x] The locked-row editor reads as committed — Philip's original complaint is resolved.

Confirmed earlier and still true: dictation into TextEdit pastes at the cursor; `contextualStrings`
and `setContext` compile; dictation cannot start while a password field has focus.

Optional and still unreached, low value: the mid-dictation secure-input toast. Worst case if wrong,
the user presses ⌘V — which the toast says anyway.

## Gotchas / things to watch for

- **Acknowledgement is not closure.** A confirmation attached to a control that stays live leaves the
  user still holding it. This cost a full round trip. Phase 9's history pane will hit the same
  question — the rule is in `BUILD-SPEC.md`.
- **`supportsVocabularyHints = true` means hints are passed, never that they help.** Unmeasured by
  choice. Do not promote the claim without evidence; the fallback order is still in `DEFERRED.md`.
- **Any new input UI needs the locked/editing split**, not a status badge bolted onto a live field.
- Earlier gotchas still hold: porting logic to Python tests the algorithm and never the Swift;
  snippets are where private data lands by design; every posted keystroke needs
  `HotkeyMonitor.syntheticMarker`; secure input blocks reading as well as writing; never paste a
  fenced code block into Terminal; read the SDK rather than guessing a symbol name twice.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and in sync with `origin`. `main` untouched. No open PRs.
- **Working tree:** clean.
- **Next step: Phase 8** — live text preview in the pill, and the last hard problem. Today the app
  records everything, then transcribes once. Live preview means transcribing continuously over
  growing audio and reconciling the engine revising itself mid-sentence. `SpeechTranscriber` already
  has the preset — `.progressiveTranscription` rather than the current `.transcription`, noted in
  `AppleTranscriber.makeTranscriber`. Apple handles the reconciliation; the work is feeding audio
  incrementally and rendering revisions without flicker.
- **Sequenced last on purpose.** If Phase 8 goes badly, everything behind it still works. Do not let
  a streaming failure destabilise the one-shot path that is currently verified.
- **Then Phase 9** — transcript history and vocabulary suggestions, both resting on Phase 7's storage.
- **`BUILD-SPEC.md` and `DEFERRED.md` were both updated this session and are current.** BUILD-SPEC
  gained the locked-row rule and the honest wording on hint effectiveness; DEFERRED gained an
  "open over time, not blocking" section.
- **No open questions.**
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
