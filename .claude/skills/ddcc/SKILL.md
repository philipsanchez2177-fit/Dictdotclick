---
name: ddcc
description: Philip's end-of-session ritual for the Dictdotclick repo (DictDotClick Calibrate). Trigger on the literal command "/ddcc", and also proactively whenever Philip signals a session is wrapping up while working on Dictdotclick — phrases like "we're done for tonight," "let's wrap up," "end the session," "update the handoff," "save our progress," or "that's it for now." Archives the current SESSION_HANDOFF.md, writes a new one capturing what happened this session, tracks Swift code that was written but not yet compiled on Philip's Mac, appends a portfolio-facing entry to docs/BUILD-JOURNAL.md if the session earns one, makes sure nothing is left uncommitted, and pushes — so a session can end in under a minute without losing any work or narrative. Only applies inside the Dictdotclick repo; use /calibrate for ORBIT and /cw-calibrate for Cowork project folders.
---

# DDCC — ending a Dictdotclick session

This is how a Dictdotclick session ends. The goal: **make ending a session quick without losing
anything that happened in it.** Everything below serves that one goal — don't add friction beyond
what's needed to actually protect the work.

Do this without asking for confirmation along the way. Committing and pushing to the feature branch
never needs approval; merging, publishing, and opening PRs do, and this skill does none of those.
Move fast, then report in one summary at the end.

## The thing that makes this project different

Dictdotclick is a **native macOS app written in Swift**. Claude sessions run in a **Linux
container**, which has no Swift compiler and no Xcode. So code gets *written* here and *proven* on
Philip's Mac — two different machines, two different moments in time.

That gap is the main thing this skill exists to manage. Code that was written but never compiled is
not finished work, and it must never be recorded as if it were. Every handoff carries an explicit
**"Needs verifying on the Mac"** list so unverified Swift can never quietly pile up.

## 0. Confirm you're in the right place

Run `git rev-parse --show-toplevel`. The path must end in `Dictdotclick`.

- If it's the ORBIT repo, stop — tell Philip to use `/calibrate` instead.
- If it's a Cowork project folder, stop — that's `/cw-calibrate`.
- If it's anything else, stop and say so.

Then check the branch with `git branch --show-current`. **If it's `main`, stop before touching
anything and tell Philip.** Every step below assumes a feature branch (normally
`claude/init-ayj2tg`), and this skill must never be the thing that puts a commit on `main`.

## 1. Bootstrap the project docs if this is the first run

Check whether these exist at the repo root. If any are missing, create them now — a first run on a
young repo is expected, not an error.

- **`BUILD-SPEC.md`** — owns current architecture and state: the locked product decisions, the tech
  stack and why each piece was chosen, which build phase is done and which is next. Seed it from
  whatever is actually true in the repo right now plus the decisions on record. Never invent a spec
  for code that doesn't exist — describe what *is*, and mark what's still planned as planned.
- **`DEFERRED.md`** — outstanding and deliberately-postponed work, with a one-line reason each.
- **`CLAUDE.md`** — repo guidance for future sessions. Must tell them to read `BUILD-SPEC.md` first,
  state that Swift can't be compiled in the container, and name the current working branch.
- **`docs/archive/`** — directory for retired handoffs.
- **`docs/BUILD-JOURNAL.md`** — created lazily in step 5, only when a session earns an entry.

If they already exist, don't rewrite them here — step 4 handles staleness.

## 2. Make sure nothing from the session is stray

Run `git status`. Anything uncommitted — staged, unstaged, or untracked, other than
`SESSION_HANDOFF.md` which steps 6–7 handle — is exactly what this skill exists to catch. A session
that produced real work but never committed it is one container-reclamation away from losing it.

For each stray change, verify as far as this environment actually allows, then commit:

**Swift files (`.swift`) — cannot be compiled here.** Do what's genuinely possible:
- Read the file end to end. Is it complete, or does it trail off mid-thought?
- Do braces, parens, and brackets balance? Are all `import`s present for what's used?
- Is the file referenced by the Xcode project (`project.pbxproj`) so it will actually build?

If it passes those, commit it — **and add it to the "Needs verifying on the Mac" list in step 7.**
Never describe Swift as "working," "verified," or "tested" when no compiler ran. Write "written, not
yet compiled."

**Xcode project files (`.pbxproj`, `.xcscheme`, `Info.plist`, entitlements).** These corrupt easily
and break the whole project when they do. Confirm the file parses as valid plist/XML/JSON where a
checker exists. Any hand-edit to `project.pbxproj` goes on the Mac-verification list without
exception — a malformed one means Xcode won't open the project at all.

**Everything else** (Markdown, JSON, shell, YAML, config): validate normally where a checker exists
— e.g. `python3 -m json.tool` for JSON. These run fine in the container, so they can be reported as
genuinely verified.

**If verification fails, or a change is a genuine half-finished edit rather than a complete piece of
work:** don't paper over it by committing something broken. Leave it uncommitted, and say so
explicitly in the handoff's "Anything to know before continuing" section *and* in the final report.
Silently losing track of unfinished work defeats this skill as thoroughly as losing a commit would.

## 3. Reconstruct what happened this session

Don't rely on conversation memory alone — long sessions get summarized, and some real work never
shows up as a file diff (a decision made but not yet acted on, something Philip did on his Mac and
reported back, a PR he merged outside this session). Ground the summary in several sources and
reconcile them:

- `git log` and `git diff --stat` from the start of the session — roughly, since the commit the
  current `SESSION_HANDOFF.md` was written against, or since this skill last ran — through `HEAD`.
- Any PRs opened, updated, or merged during the session.
- **Anything Philip reported back from his Mac.** If he ran the app, hit a build error, granted a
  permission, or confirmed something worked, that's real information that exists nowhere in git.
  Capture it — especially items it clears off the Mac-verification list.
- Your own memory of the conversation for the *why*: decisions made, options weighed, what was
  chosen and what was rejected.

## 4. Check whether BUILD-SPEC.md or DEFERRED.md went stale

Don't edit either file here — just check. If this session changed something either document
describes (a locked decision, an architecture choice, a phase completing), a future session reading
`BUILD-SPEC.md` first will get a wrong picture unless someone updates it.

If you spot a gap, note it as a bullet in the new handoff so it's a visible flag rather than a
silent one — e.g. "`BUILD-SPEC.md` still lists Phase 3 as next; Phase 3 shipped this session." If
nothing this session touched their territory, skip it. Don't manufacture a flag that isn't real.

## 5. Check whether this session belongs in the build journal

`docs/BUILD-JOURNAL.md` is Philip's portfolio-facing narrative of how Dictdotclick got built —
distinct from the handoff (session-scoped, for continuity) and from `BUILD-SPEC.md` / `DEFERRED.md`
(current-state tracking). It's append-only: never rewrite or trim an existing entry, only add a new
dated section below the existing ones.

Not every session earns one. Ask: would an outside reader evaluating AI-assisted build capability
learn something here that isn't just "continued the same task"? A phase shipping, a real bug found
and fixed, a design decision with a defensible tradeoff, a permissions or platform obstacle worked
through — those earn entries. Routine continuation does not.

If it earns one, append a dated section in narrative prose grounded in specifics — what got
built/fixed/decided, why it mattered, what friction was hit and how it resolved. Not a bullet
restatement of the handoff. If the session was routine, skip this step entirely; a padded entry to
keep a streak going is worse than no entry.

## 6. Archive the current handoff

Read the root `SESSION_HANDOFF.md`. Its header states its own date-letter (e.g. `2026-08-18-a`).
`git mv` it to `docs/archive/SESSION_HANDOFF-<that-date-letter>.md`, using **its own stated date,
not today's** — it may have been written on an earlier day. Nothing is deleted, only moved.

If there's no root `SESSION_HANDOFF.md` yet (first session), skip this.

If nothing of substance happened this session — a single question, no changes — it's fine to skip
archiving and rewriting rather than churning git history for a no-op. Say so instead of forcing
content into the format.

## 7. Write the new handoff

```
# SESSION HANDOFF — <today's date>-<next letter for today: a/b/c...>

Read `BUILD-SPEC.md` first, always — it owns current architecture and state. `DEFERRED.md` owns
outstanding work. This file is scoped to what happened this session and what to watch for next time.
Prior handoff archived at `docs/archive/SESSION_HANDOFF-<old-date-letter>.md`.

## What happened this session

[Narrative, grounded per step 3. What was asked, what was found, what changed, what shipped.]

## Needs verifying on the Mac

[Running checklist of code written in the container but never compiled or run. Carry forward any
unchecked items from the previous handoff — they don't expire until Philip confirms them. For each:
what to do, and what "working" looks like. Example:

- [ ] `HotkeyRecorder.swift` — open Settings → Hotkey, record ⌃⌥D. Expect: combo displays, no crash.
      Try recording bare `K`. Expect: rejected with an inline explanation.

If everything has been confirmed on the Mac, write "Nothing outstanding" — don't delete the section.]

## Gotchas / things to watch for

[Only if there's genuinely something worth flagging — a subtlety, an error fingerprint to recognize
later, a design-vs-implementation mismatch. Skip the whole section for an unremarkable session; a
padded gotchas section is worse than none.]

## Anything to know before continuing

[Branch name, ahead/behind main, open PR numbers and state, staleness flags from step 4, and any
stray-uncommitted-work flags from step 2.]
```

For the letter suffix: check `docs/archive/` for existing `SESSION_HANDOFF-<today>-*.md` files and
continue the sequence. First handoff of the day is `-a`; the letter on the file archived in step 6
tells you what came before.

## 8. Commit and push

Stage the archived + rewritten handoff, any docs bootstrapped in step 1, any journal entry from
step 5, and anything folded in from step 2. Commit with a message describing **what the session
did**, not the mechanism — "Add hotkey recorder with modifier/F-key validation," not "update session
handoff."

Push with `git push -u origin <current-branch>`. If it fails on a network error, retry up to 4 times
with backoff (2s, 4s, 8s, 16s). No approval needed — this is a feature-branch commit like any other
checkpoint during the session.

## 9. Report back

One short summary:

- What got committed and pushed; current branch and PR state.
- Whether a journal entry was added, or a one-line reason it wasn't.
- **Everything on the "Needs verifying on the Mac" list**, stated plainly as unverified.
- **Critically: anything that did NOT sweep up cleanly** — a verification failure from step 2, a
  staleness flag from step 4, anything left for Philip to handle by hand.

The point of this skill is that Philip can trust "ending a session" to mean nothing was lost. A
report that hides a loose end damages that trust more than the loose end itself would.
