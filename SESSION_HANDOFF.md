# SESSION HANDOFF — 2026-08-27-a

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
