# SESSION HANDOFF — 2026-08-31-a

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to pick up next. Prior
handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-28-c.md`.

## Pick up here

**Phase 9 is written, not yet built on the Mac.** Five files: four new (transcript history storage,
the suggestion engine, the suggestion approve/dismiss store, and the models file) plus a small edit to
`DictationController` to append a history row after each delivered dictation, and a full rewrite of
`HistorySettingsView` (previously a Phase 1 placeholder). Nothing else touched.

Next step is Philip pulling and building on the Mac — see the checklist below. No code review or
design questions are pending; this was a self-contained phase built end to end in one session.

## What happened this session

Built Phase 9: transcript history, and background vocabulary suggestions with approve/dismiss.

- **History** (`TranscriptHistoryStore`) appends one row per finished dictation, from the same split
  `DictationController` already computed for delivery — the raw heard text and the post-dictionary
  delivered text. Capped at 500 entries, oldest dropped first. Settings pane lists newest-first, with
  per-row delete and a confirmed "Clear All".
- **Suggestions** (`VocabularySuggestionEngine` + `VocabularySuggestionStore`) scan history for
  capitalized, mid-sentence words recurring across at least two separate dictations, excluding
  anything already in the dictionary or already dismissed. Approve adds the word to
  `DictionaryStore`; dismiss remembers a "no" so it doesn't re-ask. The heuristic and its reasoning
  are written up in `BUILD-SPEC.md` under "Phase 9".
- `HistorySettingsView` rebuilt with a suggestions card above a history card — suggestions on top
  because they're the one thing on the pane asking for a click; buried under 500 history rows they'd
  never be seen.

Full design reasoning — why the heuristic is this conservative, why approval needed no state of its
own but dismissal does — is in `BUILD-SPEC.md`, not repeated here.

## Needs verifying on the Mac

None of this has been compiled. All five files below need a build before anything on this list can
move to "verified."

| File | What to check | Success looks like |
|---|---|---|
| `Dictdotclick/History/TranscriptEntry.swift` | Compiles as part of the target. | No build errors attributable to this file. |
| `Dictdotclick/History/TranscriptHistoryStore.swift` | Dictate something, then open Settings → History. | The dictation appears as a new row, newest first. |
| `Dictdotclick/History/VocabularySuggestionEngine.swift` | Dictate the same capitalized name (not sentence-initial) in two separate dictations, e.g. "I talked to Marcus today." then later "Marcus called back." | "Marcus" appears in the Suggestions card after the second one, and not after the first. |
| `Dictdotclick/History/VocabularySuggestionStore.swift` | Click the checkmark on a suggestion, then reopen Settings → Dictionary. Separately, dismiss a different suggestion, dictate the same word again, and confirm it does not reappear. | Approved word shows up in the Vocabulary list. Dismissed word stays gone across a fresh occurrence. |
| `Dictdotclick/UI/Settings/HistorySettingsView.swift` | Open Settings → History with some entries present. Try per-row delete and "Clear All" (including cancelling the confirmation). | Layout matches the Dictionary pane's card style (Liquid Glass, locked-looking rows). Delete removes one row; Clear All empties the list only after confirming; cancel leaves it untouched. |
| `Dictdotclick/Hotkey/DictationController.swift` (edit) | Covered by the `TranscriptHistoryStore` check above — a dictation that fails to recognise anything should **not** produce a history row. | Say nothing usable into the mic, stop; no new row appears. |

## Anything to know before continuing

Nothing carried forward as a gotcha. The suggestion heuristic's *effectiveness* is deliberately
unmeasured — same call Phase 7 made about vocabulary hints — and is tracked in `DEFERRED.md` rather
than being a blocking question here.

## State

- **Branch:** `claude/init-ayj2tg`. Working tree has the Phase 9 changes, not yet pushed as of writing
  this file — pushed by the end of this session.
- **`BUILD-SPEC.md`:** updated — Phase 9 row changed to "Written, not yet built on the Mac", and a new
  "Phase 9" design section added.
- **`DEFERRED.md`:** updated — one row added to "Open over time, not blocking" for the suggestion
  heuristic's unmeasured effectiveness.
- **No open questions for Philip.**
