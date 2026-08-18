# BUILD-SPEC — Dictdotclick

**Read this first, every session.** This file owns current architecture and state.
`DEFERRED.md` owns outstanding work. `SESSION_HANDOFF.md` owns what happened last session.

Last updated: 2026-08-18

---

## What the app is

A macOS dictation utility. Press a hotkey, talk, press again to stop. Speech is transcribed
on-device and typed into whatever app is focused.

Two things differentiate it from Wispr Flow and similar tools:

1. **Toggle dictation** — press to start, press to stop. Not press-and-hold.
2. **Fully remappable trigger** — the user picks the key, within safe limits.

Design language: native macOS, Liquid Glass.

---

## Current state

**No application code exists yet.** The repo contains project tooling only:

| Path | Status |
|---|---|
| `.claude/skills/ddcc/SKILL.md` | Done — end-of-session calibrate skill |
| `.gitignore` | Done |
| `docs/archive/` | Done — empty, awaiting first archived handoff |
| Xcode project | **Not started** — Phase 0 |

**Next up: Phase 0** (scaffold the Xcode project).

---

## Locked product decisions

These were settled in an interview on 2026-08-18. Changing one is a real decision, not a detail —
update this file if any changes.

| # | Area | Decision |
|---|---|---|
| 1 | Transcription | **On-device** via whisper.cpp. No accounts, no API keys, no network calls. |
| 2 | Text delivery | **Auto-type into the focused app AND copy to clipboard.** Clipboard is the fallback for apps that reject synthetic keystrokes. |
| 3 | Recording HUD | **Floating Liquid Glass pill** with live waveform and live text preview. Draggable, position remembered. |
| 4 | Learning | **Manual dictionary + user-approved suggestions.** Two entry types (see below). Nothing is learned without a click. |
| 5 | Cleanup | **Light filler/stutter removal**, on by default, one toggle to disable. Keeps the user's wording and Whisper's punctuation. |
| 6 | Hotkey rules | **No bare character keys.** Allowed: any combo containing a modifier (⌘⌥⌃⇧), modifier-only taps (e.g. double-tap Right ⌘), and standalone function-row keys (F1–F20). |
| 7 | App home | **Menu bar only.** No Dock icon, no ⌘-Tab entry. |

### On decision 4 — the two dictionary entry types

These are different mechanisms that run at different times, and conflating them causes bugs:

- **Vocabulary hints** run *before* transcription. Fed to Whisper as a prompt so it correctly hears
  rare words — names, jargon, acronyms, "Dictdotclick".
- **Snippets** run *after* transcription. A spoken trigger phrase is replaced with stored text —
  e.g. saying "my home address" types the full street address.

Snippet trigger phrases must **also** be registered as vocabulary hints. A phrase can't be replaced
if Whisper never transcribed it correctly in the first place.

---

## Planned tech stack

Nothing here is implemented yet. Recorded so the choice and its reasoning survive.

| Piece | Choice | Why |
|---|---|---|
| Language / UI | Swift + SwiftUI | Only path to real Liquid Glass. |
| Menu bar | `MenuBarExtra` | Native SwiftUI menu-bar app, no AppKit boilerplate. |
| HUD pill | `NSPanel` (`.nonactivatingPanel`, `.floating`) | Floats above all apps including fullscreen without stealing keyboard focus. A normal window cannot do this. |
| Global hotkey | `CGEvent` tap | Hears the hotkey app-wide. Needs Accessibility permission — same one auto-typing needs, so no extra user setup. |
| Mic capture | `AVAudioEngine` | 16 kHz mono PCM (Whisper's format) plus live amplitude for the waveform. |
| Transcription | `whisper.cpp` Swift package | Whisper compiled for Apple Silicon with Metal acceleration. Offline, free. |
| Auto-typing | `CGEvent` keyboard posting | Synthesizes keystrokes into the focused app. |
| Clipboard | `NSPasteboard` | Fallback delivery path. |
| Storage | JSON in `~/Library/Application Support/Dictdotclick/` | Settings, dictionary, snippets, history. Human-readable and debuggable; no database needed at this scale. |

**Model:** start with Whisper `small.en` (~460 MB) — best speed/accuracy balance for English
dictation. Downloaded on first run, not committed to git.

---

## Build phases

Each phase ends with a **runnable app**. Never a half-broken state.

| Phase | Scope | Status |
|---|---|---|
| 0 | Xcode project, folder structure, README. Launches to an empty menu bar icon. | Not started |
| 1 | `MenuBarExtra` + Settings window with Liquid Glass and sidebar tabs. Skeleton only. | Not started |
| 2 | Permissions walkthrough — Microphone + Accessibility, with live status and a Settings deep link. Built early; it's where users get stuck. | Not started |
| 3 | Hotkey recorder enforcing decision 6, conflict detection, global `CGEvent` tap wired to a toggle. Verified with an on-screen indicator, no audio yet. | Not started |
| 4 | `AVAudioEngine` capture + glass pill with live waveform and timer. Audio captured and discarded — proves capture and UI independently. | Not started |
| 5 | whisper.cpp integrated, model downloader, transcript shown in a debug panel. **First phase where the app does its real job.** | Not started |
| 6 | Auto-type + clipboard delivery, with failure detection and a "Copied — press ⌘V" fallback toast. | Not started |
| 7 | Dictionary UI (vocabulary + snippets) and the light-cleanup post-processor with its toggle. | Not started |
| 8 | Live text preview — rolling transcription over a growing window, reconciling Whisper's revisions. Hardest part, built last. | Not started |
| 9 | Transcript history + background vocabulary suggestions with approve/dismiss. | Not started |

---

## Hard constraints

**Swift cannot be compiled in the Claude container.** Sessions run on Linux with no Swift toolchain
and no Xcode. Code is written in the container and built on Philip's Mac. Consequence: no session
may report Swift as verified or working. `SESSION_HANDOFF.md` carries a **"Needs verifying on the
Mac"** checklist that persists until Philip confirms each item.

**Liquid Glass requires macOS 26 (Tahoe).** On macOS 14/15 the app falls back to
`.ultraThinMaterial` — visually close, not identical. *Philip's macOS version is not yet confirmed
— check at Phase 1.*

**Accessibility permission is mandatory** for both the global hotkey and auto-typing. There is no
way around it; Apple gates synthetic keystrokes deliberately. Phase 2 exists to make that a smooth
one-time step.

---

## Privacy posture

Audio, transcripts, dictionary, and snippets never leave the Mac. Snippets may hold personal data
(addresses, phone numbers) by design — stored in the app's Application Support folder, never
committed to the repo. `.gitignore` excludes local data and model files.
