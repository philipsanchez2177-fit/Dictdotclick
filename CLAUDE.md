# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Read first

1. **`BUILD-SPEC.md`** — owns current architecture, locked decisions, and which build phase is next.
2. **`SESSION_HANDOFF.md`** — what happened last session, and the **"Needs verifying on the Mac"**
   checklist.
3. **`DEFERRED.md`** — outstanding work and open questions for Philip.

## What this is

Dictdotclick is a native macOS dictation app: press a hotkey, talk, press again, and the transcript
is typed into whatever app is focused. Swift + SwiftUI, menu-bar-only, Liquid Glass, transcription
on-device via whisper.cpp.

## The constraint that shapes everything

**Swift cannot be compiled in the Claude container.** Sessions run on Linux — no Swift toolchain, no
Xcode. Code is written here and built on Philip's Mac.

Therefore:

- **Never report Swift code as working, verified, or tested.** No compiler ran. Say "written, not
  yet compiled."
- Every Swift file added or changed goes on the **"Needs verifying on the Mac"** list in
  `SESSION_HANDOFF.md`, with what to do and what success looks like. Items carry forward across
  sessions until Philip confirms them.
- Hand-edits to `project.pbxproj` are especially risky — a malformed one means Xcode won't open the
  project at all. Always flag them.
- Non-Swift work (Markdown, JSON, config) *can* be validated here and reported honestly as verified.

## Working with Philip

- **Explain, then build.** Philip is new to app development. Before each step, say what's being built
  and why it's necessary, in plain English. Define any jargon on first use.
- **Be token-efficient.** Don't use ten words where three will do.
- **Suggest improvements with reasoning** — never just "here's what I did."
- **Incremental delivery.** Every phase ends with a runnable app. Never leave it half-broken.
- **Recommend, don't survey.** When there's a choice, give the recommendation and the reason.

## Branch and commit rules

- Work on `claude/init-ayj2tg`. **Never commit to `main`.**
- Committing and pushing to the feature branch needs no approval. Merging, publishing, and opening
  PRs do.
- End sessions with **`/ddcc`** — it sweeps up uncommitted work, archives and rewrites the handoff,
  updates the Mac-verification list, and pushes. (`/calibrate` is ORBIT's; don't use it here.)

## Privacy

Audio, transcripts, dictionary, and snippets stay on the Mac. Snippets may contain personal data
(addresses, phone numbers) by design — they live in `~/Library/Application Support/Dictdotclick/` and
must never be committed to this repo.
