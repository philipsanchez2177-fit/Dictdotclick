# Dictdotclick

A native macOS dictation app. Press a hotkey, talk, press again — the transcript is typed into
whatever app is focused.

Two things set it apart from Wispr Flow and similar tools:

1. **Toggle dictation** — press to start, press to stop. Not press-and-hold.
2. **Fully remappable trigger** — you pick the key, within safe limits.

Transcription runs **entirely on-device** via whisper.cpp. No accounts, no API keys, no network
calls. Audio, transcripts, dictionary, and snippets never leave the Mac.

## Requirements

- macOS 26 (Tahoe) — earlier versions work but fall back from Liquid Glass to `.ultraThinMaterial`
- Xcode 26
- Apple Silicon Mac (whisper.cpp uses Metal acceleration)

## Building

```
open Dictdotclick.xcodeproj
```

⌘R. No dependencies to install and no signing account needed — free local signing is enough to run
it on your own Mac.

On first launch the app asks for **Microphone** and **Accessibility** permissions. Both are
mandatory: Accessibility is what lets the app hear a global hotkey and type into other apps. Apple
gates synthetic keystrokes deliberately; there is no way around it.

## Build phases

Each phase ends with a runnable app — never a half-broken state.

| Phase | Scope | Status |
|---|---|---|
| 0 | Xcode project, folder structure, README. Launches to an empty menu bar icon. | In progress |
| 1 | `MenuBarExtra` + Settings window, Liquid Glass, sidebar tabs. Skeleton only. | Not started |
| 2 | Permissions walkthrough — Microphone + Accessibility, live status, Settings deep link. | Not started |
| 3 | Hotkey recorder, conflict detection, global `CGEvent` tap wired to a toggle. | Not started |
| 4 | `AVAudioEngine` capture + glass pill with live waveform and timer. | Not started |
| 5 | whisper.cpp integrated, model downloader, transcript in a debug panel. | Not started |
| 6 | Auto-type + clipboard delivery with failure detection and fallback toast. | Not started |
| 7 | Dictionary UI (vocabulary + snippets) and the light-cleanup post-processor. | Not started |
| 8 | Live text preview — rolling transcription with revision reconciliation. | Not started |
| 9 | Transcript history + background vocabulary suggestions. | Not started |

## Repo map

| File | Owns |
|---|---|
| `BUILD-SPEC.md` | Architecture, locked product decisions, current state |
| `SESSION_HANDOFF.md` | Last session's work and the Mac-verification checklist |
| `DEFERRED.md` | Outstanding work and open questions |
| `docs/BUILD-JOURNAL.md` | Portfolio-facing narrative of the build |
| `CLAUDE.md` | Instructions for Claude Code sessions |

## A note on how this is built

Claude Code sessions for this project run on Linux — no Swift toolchain, no Xcode. Swift is written
in the container and compiled on the Mac. No session may report Swift code as working or verified;
`SESSION_HANDOFF.md` carries a **"Needs verifying on the Mac"** checklist that persists until each
item is confirmed by an actual build.
