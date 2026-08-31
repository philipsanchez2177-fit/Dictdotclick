# DEFERRED — Dictdotclick

Outstanding and deliberately-postponed work. `BUILD-SPEC.md` owns current state; this file owns
what's *not* done and why.

Last updated: 2026-08-19

---

## Open questions — need Philip

| Question | Why it matters | Needed by |
|---|---|---|

### Answered

| Question | Answer | Date |
|---|---|---|
| Preferred default hotkey? | **Double-tap `` ` ``.** A single bare backtick was asked for first, but it would make the key untypable — see BUILD-SPEC decision 6. | 2026-08-19 |
| What macOS version is on Philip's Mac? | **macOS 26 (Tahoe)** — full Liquid Glass available, no fallback path needed. | 2026-08-19 |
| Is Xcode installed? | **Yes** — installed and working. | 2026-08-19 |
| Does the hand-authored Xcode project open and build? | **Yes** — `BUILD SUCCEEDED`, app launches. Xcode's New Project wizard is out of the workflow permanently. | 2026-08-19 |
| Apple Developer account needed to run locally? | **No** — "Sign to Run Locally" works with no Apple ID configured. Still required only to distribute to other people. | 2026-08-19 |

---

## Cut from a phase, not yet rebuilt

| Item | Why it was cut | Cost |
|---|---|---|
| **Hotkey conflict detection** (Phase 3) | Planned, then dropped during implementation without being called out — the phase row in `BUILD-SPEC.md` was quietly edited to match. Recorded here so the gap is visible rather than forgotten. | Found the hard way on 2026-08-19: recording ⌃⌥D triggered Magnet, which had already claimed it. |

Confirmed the same day: ⌃⌥D never reached the recorder at all — the field stayed in its listening
state while Magnet resized a window. An upstream tap can consume a keystroke entirely, so "the
recorder saw nothing" is itself a conflict signal.

**On why it is genuinely hard.** macOS publishes no registry of hotkeys other apps have claimed.
Third-party apps (Magnet, Raycast, Alfred) grab keys with the same system-wide mechanism Dictdotclick
uses, and they are invisible to us until a keystroke produces unexpected behaviour.

What *is* achievable, if it earns a slot later:

- Warn on Apple's own shortcuts, readable from `com.apple.symbolichotkeys`.
- After recording, offer a "test it" step so a collision surfaces immediately rather than a week
  later.
- Treat "the app never saw the keystroke" as evidence of a conflict: if the recorder times out
  waiting for a key the user says they pressed, something upstream swallowed it.

## Answered by reading the SDK

| Question | Answer | Date |
|---|---|---|
| Does `SpeechAnalyzer` support vocabulary hints? | **Yes.** `AnalysisContext.contextualStrings` takes `[ContextualStringsTag: [String]]`, applied via `SpeechAnalyzer.setContext`. Wired into `AppleTranscriber`; Phase 7 supplies the dictionary. Decision 4 stands and whisper.cpp stays retired. | 2026-08-22 |

Still to test with real vocabulary in Phase 7: whether the hints *measurably* improve recognition of
a rare word. The API is wired; its effect is unmeasured.

## Open over time, not blocking

| Item | Why it is not a task | What would reopen it |
|---|---|---|
| **Do vocabulary hints actually improve recognition?** | Phase 7 closed 2026-08-26 without measuring it. Mishearings surface over weeks of dictation, not on demand, and a contrived one-word test would answer less than real use. The plumbing is verified; the effect is not. | Philip adding a word and finding it *still* misheard afterwards. That is the negative result, and it is worth acting on rather than living with. |
| **More snippets, more vocabulary** | Expected to grow as real friction shows up. Not a phase; the editor already supports it. | Nothing — this is just use. |
| **Does Phase 9's suggestion heuristic surface real words, or mostly noise?** | Written 2026-08-31, not yet run against real dictations. Same reasoning as the vocabulary-hints question above — needs weeks of accumulated history, not a contrived test. | A run of suggestions that are mostly dismiss-clicks rather than real recurring words. If that happens, tighten `minimumOccurrences` or the capitalization rule in `VocabularySuggestionEngine` before considering a different approach. |
| **Auto-copy Release build to `/Applications` on every build** | Philip built and located the standalone `.app` manually on 2026-08-31 and it worked fine. A build-phase script would save the manual export/Finder-hunt step but isn't needed yet. | Philip finding the manual export step annoying after doing it a few more times. |

If hints prove ineffective, the fallback order below is still the plan.

## Worth reaching for later

| Item | Why | When |
|---|---|---|
| **`SFCustomLanguageModelData`** | A heavier alternative to a word list: custom pronunciations (`CustomPronunciation`), phrase weighting (`PhraseCount`), and templates. Stronger than whisper.cpp's initial prompt ever was. Only worth it if plain `contextualStrings` proves too weak — a word list is far simpler to build a UI around. | Phase 7+, only if needed |
| **`DictationTranscriber`** | Sibling module whose presets are named for this use case — `.shortDictation`, `.longDictation`, `.progressiveLongDictation`. Possibly better tuned than the general `SpeechTranscriber`. | Phase 7 |
| **Streaming vocabulary hints, mid-dictation** | Phase 8's live session sets `contextualStrings` once, at session open, from the dictionary as it stood when dictation started — same rule the one-shot path already used. A word added to the dictionary *during* a long dictation won't bias that dictation. Consistent with existing behaviour, just worth naming now that sessions can run long enough for it to matter. | If a long-dictation workflow makes this a real friction point |

## Deferred by decision

Considered during the 2026-08-18 interview, deliberately postponed. Not forgotten, not rejected.

| Item | Reason |
|---|---|
| Cloud transcription option | Local-only chosen for v1: no cost, no accounts, fully private. Could return as a Settings toggle if local accuracy disappoints. |
| AI "rewrite/polish" hotkey | A second hotkey running a local LLM to turn dictation into polished prose. Needs another model download and reopens the local/cloud tradeoff. Later phase. |
| Fully automatic vocabulary learning | Rejected for v1 — an app that silently learns a wrong word and then insists on it is painful to debug and undo. Suggestions require approval instead. |
| Learning from user corrections | Watching what Philip edits *after* the app types would be powerful, but requires reading text out of other apps — invasive and unreliable. Not planned. |
| Multi-language support | English-only (`small.en` model) for v1. Whisper supports many languages; a multilingual model is a larger download and slower. |
| App distribution / notarization | Only relevant if the app ships beyond Philip's own Mac. Requires a paid Apple Developer account. |

---

## Known risks

| Risk | Note |
|---|---|
| Phase 8 (live preview) is the hard one | Rolling transcription with revision reconciliation. Sequenced last deliberately so a failure there leaves a fully working app behind it. |
| Whisper model size vs. accuracy | `small.en` is the starting bet. If accuracy disappoints, `medium.en` (~1.5 GB) is the next step up — slower, bigger download. |
| Synthetic keystrokes are refused in some contexts | Secure input fields (passwords), some VMs and remote desktops. Mitigated by the clipboard fallback in Phase 6, not eliminated. |
| No CI is possible | Nothing in this repo can be built or tested by an automated runner without a macOS machine. All verification is manual, on Philip's Mac. |
