# SESSION HANDOFF — 2026-08-26-a

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-22-b.md`.

## What happened this session

**Phase 7 shipped — the dictionary.** Written, not compiled. This is the phase the app was pitched
on: the difference between a tool that hears "dict dot click" and one that learns your words.

Three things, and the first two are the ones from the opening interview:

- **Vocabulary hints** — words fed to the engine *before* it listens, so rare terms are heard
  correctly. The plumbing went in four days ago; this phase builds the UI and fills the list.
- **Snippets** — a spoken trigger replaced with stored text *after* transcription. Every snippet
  trigger is also registered as a vocabulary hint automatically, because a phrase heard wrong can
  never be matched and replaced. That dependency was spotted in the first interview and is now
  enforced in code rather than remembered.
- **Filler cleanup** — strips "um", "uh", stutters and repeated words, with the toggle decision 5
  asked for. Restores the capital when removing a leading filler turns the next word into the
  sentence start.

**The interesting problem was testing logic that cannot be compiled here.** Previous phases were
mostly UI, where a compile failure is loud and immediate. A snippet matcher is different: it can
compile perfectly and still be wrong on inputs nobody thought about.

So the matcher and the cleanup pass were ported to Python — the same algorithm, not a rewrite — and
run against ten cases: trigger followed by punctuation, longest-trigger-wins on overlap, no match
inside a longer word (`my address` must not fire inside `my addressee`), an expansion containing its
own trigger not looping, and the capital-restoration edge in the filler stripper. All ten pass.

**Be precise about what that buys.** It tests the *algorithm*, not the Swift. A typo, a wrong API, an
off-by-one present in one language and not the other — none of it is caught. What it does is split
"is the logic right" from "does it compile": one question answered now, one the Mac answers in
seconds.

**One claim deliberately left unmade.** `supportsVocabularyHints = true` means hints are passed to
the engine. Whether they *improve* recognition is unmeasured. The General pane now shows what the
engine heard before the dictionary was applied, next to the final text — that is the instrument for
the measurement, not a debugging leftover.

## Needs verifying on the Mac

**Phase 7 is written and has never been compiled.** Four new Swift files, three edited. No
`project.pbxproj` changes — the synchronized folder group picks new files up on its own. If it does
not, that itself is the finding.

New: `Dictionary/DictionaryModel.swift`, `Dictionary/DictionaryStore.swift`,
`Text/TranscriptPostProcessor.swift`, `Storage/AppSettings.swift`.
Rewritten: `UI/Settings/DictionarySettingsView.swift`.
Edited: `Hotkey/DictationController.swift`, `UI/Settings/GeneralSettingsView.swift`.

- [ ] **It builds**, and the new files appear in the target without being added by hand.
- [ ] **Snippets.** Dictionary pane → Add snippet, trigger `my address`, expansion your address.
      Dictate "please send it to my address" into TextEdit. Expect the address, not the phrase.
      Quit and relaunch; the snippet should still be there.
- [ ] **Vocabulary hints — the one measurement this phase owes.** Pick a word the app currently gets
      wrong (a surname, "Dictdotclick"). Dictate it, note the result. Add it as a vocabulary word,
      dictate the same sentence again. The General pane's "heard before the dictionary was applied"
      line makes the before/after visible. **Whether it improves is the finding either way** — a
      negative result means `supportsVocabularyHints` goes back to false and `DEFERRED.md`'s fallback
      order (`SFCustomLanguageModelData`, then `DictationTranscriber`, then whisper.cpp) comes off
      the shelf.
- [ ] **Filler cleanup.** General → Remove filler words on. Dictate "um, so, this is, uh, a test".
      Expect "So, this is a test" — capital restored, no stray comma at the front.
- [ ] **Nothing is committed that shouldn't be.** `dictionary.json` and `settings.json` live in
      `~/Library/Application Support/Dictdotclick/`. Confirm neither appears in `git status`. This
      matters more than usual now: snippets are where personal data lands by design.

Confirmed earlier and still true:

- [x] Dictation into TextEdit: hotkey, speech, transcript pasted at the cursor.
- [x] `AnalysisContext.contextualStrings` and `SpeechAnalyzer.setContext` compile as written.
- [x] Dictation cannot be started while a password field has focus — expected, and documented.

Optional, low value: the mid-dictation secure-input toast. Start in TextEdit, click into a password
field while recording, then press the hotkey to stop. Worst case if wrong: the user presses ⌘V, which
the toast says anyway.

## Gotchas / things to watch for

- **Porting logic to Python tests the algorithm, never the Swift.** Useful, and precisely bounded.
  Do not let a passing Python run appear anywhere as evidence the Swift works.
- **Snippets are where private data enters this repo's blast radius.** `.gitignore` does not cover
  Application Support because nothing there is inside the repo — but any future feature that exports,
  logs, or backs up the dictionary needs deliberate thought about where it writes.
- **Every keystroke this app posts must carry `HotkeyMonitor.syntheticMarker`.** Still true, and now
  more relevant: snippet expansions make transcripts contain text the user never spoke.
- **Handoff date labels have drifted from commit dates.** The file labelled `2026-08-22-b` was
  committed on the 24th; this one is labelled from the container clock (26th). The sequence is
  correct and the archive is ordered; only the labels are approximate. Not worth rewriting history
  over — worth knowing before trusting a date in an archived filename.
- Earlier gotchas still hold: secure input blocks reading as well as writing; never paste a fenced
  code block into Terminal; read the SDK rather than guessing a symbol name twice; Team must stay set
  in Signing & Capabilities; nothing non-source inside `Dictdotclick/`.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and in sync with `origin`. `main` untouched. No open PRs.
- **Working tree:** clean.
- **Next step: Phase 8** — live text preview in the pill. The hardest remaining phase, sequenced last
  deliberately. It means moving from one-shot transcription to rolling transcription over a growing
  window, reconciling revisions as the engine changes its mind. `SpeechTranscriber` already has the
  preset for it: `.progressiveTranscription` rather than the current `.transcription`, noted in
  `AppleTranscriber`. **Do not start Phase 8 before Phase 7 is verified on the Mac** — building
  streaming on top of an unproven dictionary would make a failure ambiguous.
- **Then Phase 9** — transcript history and vocabulary suggestions, which depend on Phase 7's storage.
- **A stale line was corrected this run.** The previous handoff still said "Next step: Phase 7" after
  Phase 7 had shipped. `BUILD-SPEC.md`'s phase table was already correct.
- **`BUILD-SPEC.md` and `DEFERRED.md` are current.**
- **No open questions.** The one unanswered thing is a measurement, not a decision, and it is on the
  checklist above.
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
