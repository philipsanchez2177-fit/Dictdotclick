# SESSION HANDOFF — 2026-08-20-a

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-2026-08-19-b.md`.

## What happened this session

**Phases 2 and 3 both shipped and are fully verified on the Mac.** The app now responds to the user
for the first time: pressing the bound hotkey from inside any app toggles its listening state.

**Phase 2 — permissions walkthrough.** Its own window rather than a Settings tab, because it is a
task with an end state rather than preferences to browse. Reads Microphone (AVFoundation) and
Accessibility (`AXIsProcessTrusted`), offers the system prompt where one exists, and deep-links to
the right System Settings pane. Polls once a second while open and stops on close — macOS sends no
notification when a permission changes, so without polling the window keeps showing a red dot after
the user has already granted access.

Every path was exercised, including the ungranted ones. Apple's undocumented
`x-apple.systempreferences:...PrivacySecurity.extension?Privacy_*` deep links land correctly on
macOS 26.

**Phase 3 — the global hotkey.** A `CGEvent` tap watching for one binding, swallowing it on a match
and passing everything else through. Recorder UI enforcing decision 6, rejections explained inline,
binding persisted to `hotkey.json` through a new `JSONStore`. An `AppDelegate` was added purely to
start the monitor at launch: every scene in this app is `.defaultLaunchBehavior(.suppressed)`, so no
Scene `.task` runs until a window opens, and a hotkey that only works after visiting Settings is not
a hotkey.

**The session's real cost was a permission that would not stick.** The tap did nothing on first run.
System Settings showed Dictdotclick switched **on** while `AXIsProcessTrusted()` returned false —
both true at once. macOS ties the grant to the app's *code signature*, and with **Team: None** Xcode
signs each build "to run locally" with an ad-hoc identity regenerated every time. Every ⌘R produced
an app macOS had never seen; the list entry pointed at a build that no longer existed.

Fixed durably by setting a development team (free Apple ID), which produces a stable
`Apple Development` signature. Without it this would have recurred on every build for the remaining
six phases.

**A decision reversed.** The double-tap was planned as "let the first press through, delete both
characters if a second arrives" — no latency. Writing it made the cost concrete: it means
synthesising Delete into whatever window is focused, which in a spreadsheet clears a cell, silently.
Reversed to holding the first press ~200 ms and replaying it if no second comes. Confirmed on the Mac
that a single backtick still types normally.

**Two things the plan had wrong about the world**, both now recorded:
- **Function keys are unusable on this Mac** — Logitech software claims the F row. One of decision
  6's three allowed shapes is not available to Philip.
- **Conflict detection was cut from Phase 3** without being flagged, and the phase table was edited
  to match. Surfaced when recording ⌃⌥D resized a window — Magnet had claimed it and consumed the
  keystroke before the recorder saw it. Now in `DEFERRED.md` with what is achievable.

## Needs verifying on the Mac

**Nothing outstanding.** No uncompiled Swift exists in the repo.

Confirmed 2026-08-20:

- [x] Permissions window: reads both permissions, renders, and every path works — the system prompt,
      the System Settings deep link, and the polling that turns a badge green with no interaction in
      the app.
- [x] `CGEvent` tap toggles listening state from inside another app; the menu bar icon reflects it.
- [x] A single backtick still types normally, so the hold-and-replay does not eat a key.
- [x] Recorder accepts valid bindings and refuses bare character keys with the reason shown inline.
- [x] Binding survives quit and relaunch via `hotkey.json`, confirming `JSONStore` works.
- [x] A stable `Apple Development` signature keeps the Accessibility grant across rebuilds.

## Gotchas / things to watch for

- **Team must stay set in Signing & Capabilities.** If it ever reverts to None, the app signs
  ad-hoc again and Accessibility silently stops applying after the next build. That symptom —
  System Settings says on, the app says off — means signing, not code.
- **Recovering a stale Accessibility entry:** select Dictdotclick in System Settings → Privacy &
  Security → Accessibility, click **−** to remove it, then use **Request Access** in the app.
  Toggling the old entry does not work; it re-approves a build that no longer exists.
- **Philip's binding is ⌘\` , not the shipped default** (double-tap backtick). ⌘\` is macOS's
  "cycle windows within app" shortcut, so binding it likely shadows that. Accepted knowingly — not a
  bug.
- **Nothing non-source goes inside `Dictdotclick/`,** and no same-named files at any depth. The
  synchronized folder compiles or copies everything it finds.
- **Six compile errors often means one real problem.** `HotkeyRejection` missing `Error` conformance
  produced six; five were cascade. Start at the top of Xcode's list.
- Earlier gotchas that still hold: never `git rev-parse --show-toplevel` in a fresh Terminal; never
  launch the built `.app` directly; always Replace at Xcode's Replace/Add prompt; don't use
  `NavigationSplitView` for fixed panes.

## Anything to know before continuing

- **Branch:** `claude/init-ayj2tg`, pushed and in sync with `origin`. `main` untouched. No open PRs.
- **Working tree:** clean.
- **Next step: Phase 4** — `AVAudioEngine` capture plus the floating Liquid Glass pill with a live
  waveform and timer. Audio is captured and discarded, deliberately: it proves microphone and visuals
  work independently, so when Phase 5 adds Whisper a failure is unambiguous. The pill is an
  `NSPanel` (`.nonactivatingPanel`, `.floating`), not a `Window` — it must float above fullscreen
  apps without taking keyboard focus. `.glassEffect` is already proven.
- **`BUILD-SPEC.md` and `DEFERRED.md` were both updated this session** and are current, not stale.
  BUILD-SPEC gained four sections: the signing trap, the F-row finding, the double-tap
  implementation decision, and Philip's actual binding.
- **No open questions.** The default-hotkey question is answered and closed.
- **`SWIFT_VERSION` is still 5.0.** Untouched, still not worth revisiting.
- **Standing reminder:** explain before building, plain English, define jargon on first use, keep
  responses tight.
