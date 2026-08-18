# DEFERRED — Dictdotclick

Outstanding and deliberately-postponed work. `BUILD-SPEC.md` owns current state; this file owns
what's *not* done and why.

Last updated: 2026-08-18

---

## Open questions — need Philip

| Question | Why it matters | Needed by |
|---|---|---|
| What macOS version is on Philip's Mac? | Liquid Glass needs macOS 26 (Tahoe). Below that we fall back to `.ultraThinMaterial`. Changes what Phase 1 can look like. | Phase 1 |
| Is Xcode installed? | Nothing can be built or run without it. Free from the Mac App Store, ~10 GB. | Phase 0 |
| Apple Developer account? | Not needed to run the app locally on his own Mac (free signing works). Only needed to distribute it to anyone else. | Only if sharing |
| Preferred default hotkey? | Ships as the out-of-box default; user-changeable in Settings. | Phase 3 |

---

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
