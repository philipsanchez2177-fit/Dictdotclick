# BUILD JOURNAL — Dictdotclick

A portfolio-facing narrative of how this app got built. Append-only: new entries go at the bottom,
existing ones are never rewritten or trimmed.

---

## 2026-08-18 — Deciding before building

The session that started Dictdotclick produced no application code at all, which turned out to be
the right outcome.

The brief was a Wispr Flow–style dictation app with two differences: dictation toggles on a keypress
rather than requiring a held key, and the trigger key is fully user-mappable. Native macOS look,
Liquid Glass. The obvious move was to start scaffolding an Xcode project. Instead the session ran an
interview first — six questions, one at a time, each with a recommendation and the reasoning behind
it.

That structure paid off immediately, because two of the six answers came back different from the
recommendation, and both changes were substantive.

The first was the recording indicator. The recommendation was a floating glass pill with a live
waveform — enough to prove the microphone is hearing you. The answer added live text preview on top
of it. That is not a cosmetic upgrade. A waveform needs amplitude data, which the audio engine
already produces for free. Live text needs the transcriber running repeatedly over a growing buffer,
reconciling its own earlier guesses as later audio arrives and changes the model's mind about what
it heard. It moved from a Phase 4 detail to its own phase, sequenced dead last specifically so that
if it goes badly, everything behind it is still a working app.

The second was vocabulary. The question was about teaching the transcriber rare words — names,
jargon, acronyms. The answer asked for something adjacent that sounded like the same feature and
isn't: saying "my home address" should type out the actual street address. Those are two mechanisms
running at opposite ends of the pipeline. Word hints go *in* before transcription, as a prompt that
biases the model toward hearing a term correctly. Phrase expansion happens *after*, as a
find-and-replace on finished text. They also have a dependency that's easy to miss until it bites:
an expansion trigger must itself be registered as a word hint, because a phrase that was transcribed
wrong can never be matched and replaced. Catching that during an interview cost a paragraph.
Catching it after both features shipped would have cost a confusing bug report and a refactor.

The hotkey question produced the session's cleanest tradeoff. The stated goal was "any key or
combination." The problem with honoring that literally is that mapping a bare letter means the app
has to swallow that keystroke globally, and the user now owns a keyboard that can't type the letter
K. The recommendation was to allow anything but warn on risky choices. The answer was better:
modifier combinations and function-row keys only. Function keys are the elegant part — they're
standalone, they're not needed for typing prose, and they sidestep the entire problem class without
the warning UI the recommendation would have required. Less code, fewer states, no foot-gun.

### The constraint worth writing down

Partway through it became clear the build environment could not build the product. Claude sessions
run in a Linux container. A SwiftUI app needs Xcode on a Mac. Code can be written in one place and
only ever proven in another.

The failure mode there is quiet and corrosive: a session writes four Swift files, commits them,
reports success, and everyone proceeds as though four working files exist. Ten phases later, the
first compile surfaces a pile of errors with no clear owner.

So the session's only real artifact was a piece of process tooling — a `/ddcc` command that ends a
session by sweeping up uncommitted work, reconstructing what happened, and pushing. Modeled on an
existing ritual from another project, with one addition specific to this one: every session handoff
carries a **"Needs verifying on the Mac"** checklist. Each Swift file added goes on it, with the
steps to exercise it and a description of what working looks like. Items persist across sessions
until confirmed by hand. The rule backing it is stated in `CLAUDE.md` and is deliberately absolute:
never describe Swift as verified when no compiler ran. Write "written, not yet compiled."

It's a small thing. It's also the difference between a checklist that tracks reality and a status
report that tracks optimism.

Zero lines of application code. Seven locked decisions, a phase plan, and a mechanism to keep the
next twenty sessions honest.

---

## 2026-08-19 — The wall was the tooling, not the code

The plan said Phase 0 would be scaffolding an Xcode project. What actually happened is that the
project's human hit a wall, and the fix was to remove the wall rather than to coach him over it.

The setup handed to him was a five-step walkthrough: run Xcode's New Project wizard, fill in seven
fields, add an `Info.plist` key by hand, swap one generated file for another, delete a second, create
eight groups. Every step is unremarkable to someone who has done it before. To someone who hasn't,
it's five chances to end up somewhere unrecoverable — and he did. The first sign of trouble was a
screenshot of a Swift file containing `cd Dictdotclick`, `git pull`, and `open
Dictdotclick.xcodeproj`, with Xcode complaining it couldn't find `cd` in scope. Terminal commands
pasted into a code editor. Perfectly reasonable mistake: nobody had said which of the two apps on
screen was which.

The instinct is to write clearer instructions. The better move was to ask why the instructions
existed at all. Xcode's wizard produces a `.xcodeproj` — a directory whose central file,
`project.pbxproj`, is just structured text. It could be authored directly and committed, reducing
his job to `git pull` and ⌘R forever. The reason nobody does that is that the format historically
enumerated every source file individually, so it drifted out of sync constantly and a malformed one
stops Xcode opening the project at all. The project's own `CLAUDE.md` carried a warning to that
effect.

That warning turned out to be out of date. Xcode 16 added file-system-synchronized groups: the
project references a *folder* and compiles whatever it finds. The file stops being a manifest that
must track reality and becomes a small static description of a target. It can be written once,
validated, and left alone — and future sessions add `.swift` files without touching it. The most
fragile recurring step in the project disappeared, which is a much better outcome than getting good
at performing it carefully.

It was written, checked in-container for balanced delimiters, resolving object references, and
correct target wiring, and committed with the honest caveat that structural validity is not the same
as Xcode accepting it.

Then the diagnosis got interesting. A command to survey his Mac turned up one clone and one
`.xcodeproj`, and a test for whether the project file was the committed one or the wizard's reported
"MINE." That test was wrong — modern Xcode generates synchronized-folder projects too, so the check
couldn't distinguish them. The real tells were `Assets.xcassets`, a `ContentView.swift`, a branch
named `main`, and a single commit called "Initial Commit": a local repo Xcode had created, with no
relationship to the one on GitHub. Two projects that appeared stacked were actually unrelated. The
correction mattered more than the original answer, because the wrong reading would have led to
merging two unrelated git histories to no purpose.

The clone succeeded, and the build failed: `Multiple commands produce .../DerivedData/...`,
alongside nine errors pointing at a `ContentView.swift` that didn't exist in the new project. The
nine were stale cache from the abandoned project. The first one was a real bug, and it was a
self-inflicted one. Seven empty folders had been created to give future phases a home, and because
git cannot store an empty directory, each got a placeholder named `.gitkeep`. Synchronized folders
sweep up every file, not just Swift ones — so seven identically-named files all resolved to the same
destination in the app bundle, and the build system refused. The convenience feature that removed
the fragile step introduced a new failure mode in the same stroke.

The placeholders came out, the empty folders with them, and the rule went into the spec: nothing
non-source inside the synchronized folder, and no same-named files anywhere under it. `**BUILD
SUCCEEDED**`, a microphone icon in the menu bar, and a Settings window that opened in front on the
first try — notable because `SettingsLink` inside an agent app had been flagged as the most likely
thing to need a workaround, and didn't.

Two things are worth keeping from the evening. The `.gitkeep` diagnosis was a hypothesis pushed
without proof, labeled as one in the commit message, and confirmed only by the next build; treating
it as a fix at the time would have been a small lie that happened to come true. And the wizard was
never the point. It was a step someone had to perform because that was how it had always been done,
and one look at whether it was still necessary removed it from every future session.

---

## 2026-08-19 — The same bug three times

Phase 1 was the first real interface: a Settings window with a sidebar — General, Hotkey,
Dictionary, History — and Liquid Glass, macOS 26's light-bending material. The window is a skeleton
by design. Each pane holds a card naming the phase that will fill it in. The point of the phase was
not the controls; it was to prove the material renders at all, because Phase 4's floating recording
pill depends on it and finding out then would have been expensive.

It also forced a decision that had been deferred since Phase 0. Liquid Glass exists only on macOS
26, and the project targeted macOS 14 to maximise the odds of a first build succeeding. The
alternative to raising the target was gating every glass call behind an availability check and
maintaining a second, non-glass version of every screen — real work whose only beneficiaries would
be users who do not exist. The target went to 26.0. That is a decision to revisit if the app ever
ships beyond one Mac, and it is written down as such rather than left implicit in a build setting.

The code was written, pushed, and built on the Mac. It compiled. `.glassEffect` rendered. And the
sidebar was empty — four rows that simply were not there, with the split view's collapse button
sitting above them as proof the container existed.

The first diagnosis blamed SwiftUI's `Settings` scene, the built-in window that ⌘, opens, for not
giving a two-column layout room to lay out. The window moved to an ordinary `Window` scene the app
controls outright. The rows appeared. Two more rounds went to window sizing — a size constraint
dropped during the rewrite, then an infinite maximum that seemed to be feeding the resize logic a
minimum. Then the rows vanished again on resize, and the pattern finally became legible.

`NavigationSplitView` was the cause every time. It is built for navigation hierarchies, and it
decides on its own when to collapse, hide, and restore its columns based on available space —
correct for a drill-down, wrong for four fixed rows that must always be visible. The `Settings`
scene had been a bystander. The window is now a plain horizontal stack with a fixed-width list:
nothing negotiates, nothing collapses, the layout is identical at every size. What made this worth
recording is not the fix but the misattribution. The first diagnosis produced a working sidebar,
which is exactly why it survived — a change that makes the symptom go away is nearly indistinguishable
from a change that addresses the cause, and only the recurrence told them apart. The five layout
rules the phase produced went into the spec, because Phase 2 builds another window and would
otherwise have paid for them again.

The other lesson had nothing to do with Swift. A block of terminal commands handed over for pasting
began with `cd "$(git rev-parse --show-toplevel)"` — a command that finds the repository root, and
which only works when run from somewhere inside the repository. Pasted into a freshly opened
terminal, which starts in the home folder, it failed, and so did every git command chained behind
it. The pull never happened. Two rounds of "the fix didn't work" followed, spent testing a build
that predated the fixes entirely. The clever command was clever in a context that did not hold, and
an absolute path would have been correct in every context. When someone reports that a fix did not
work, the first question is whether they have the fix.

Phases 0 and 1 are verified on the Mac. Liquid Glass renders, the macOS 26 target builds clean, and
the app still launches to nothing but a microphone icon in the menu bar.

---

## 2026-08-20 — Two phases, and a permission that would not stick

Phases 2 and 3 both shipped: the permissions walkthrough, and the global hotkey. The hotkey is the
first thing in this app that responds to the user, and getting there cost an hour of debugging a
problem that was not in the code at all.

### Building the wall before the door

Phase 2 was sequenced deliberately early. A dictation app needs two macOS permissions — Microphone to
hear, Accessibility to watch the keyboard and type the result — and Accessibility is the most
powerful grant on the platform. An app that holds it can read and synthesise every keystroke on the
machine. Apple gates it behind a padlock and an admin password for exactly that reason, and it is
where users of this category of app give up.

Two permissions, two unrelated APIs. Microphone reports four distinct states through AVFoundation and
can raise the system prompt once. Accessibility answers a bare `AXIsProcessTrusted()` boolean that
cannot distinguish "refused" from "never asked". Neither notifies anyone when the answer changes: a
user grants permission in System Settings, switches back, and the app is still showing a red dot
because nothing told it otherwise. That moment is when people conclude software is broken, so the
window polls once a second while it is open and stops the instant it closes.

That paid off immediately. Walking a permission from scratch showed Apple's own prompt, a deep link
landing directly on Privacy & Security → Accessibility, and a badge turning green with no interaction
in the app at all. The deep-link URL scheme is undocumented and has changed between macOS releases,
so it was the least certain part of the phase and worth confirming rather than assuming.

### The permission that would not stick

Phase 3 built the event tap, and it did nothing. Backticks typed straight through as if the app were
not running.

The obvious read was a bug in the tap. The actual cause was that System Settings showed Dictdotclick
switched **on** while `AXIsProcessTrusted()` kept returning false. Both statements were true at once.

macOS ties an Accessibility grant to the app's *code signature*. With no development team configured,
Xcode signs each build "to run locally" with an ad-hoc identity regenerated every time. Every ⌘R
therefore produces an application macOS has never seen before, and the entry sitting in the
permissions list points at a build that no longer exists. Toggling it re-approves a ghost.

Two fixes, and only one of them is durable. The immediate recovery is to delete the stale entry
outright and let the app re-register itself — which surfaced a genuine gap in the UI, since the
accessibility row only ever offered "Open System Settings". Because the API always reports untrusted
as denied, the code path that raises Apple's prompt was unreachable from the interface, and that
prompt is precisely what re-registers the current build. A "Request Access" button went in.

The durable fix is to sign the app with a stable identity. Setting a development team — a free Apple
ID is enough — produces an `Apple Development` certificate that does not change between builds, so
the grant survives. Without it, this would have recurred on every single build for the remaining six
phases. The hour spent on it bought back the rest of the project.

### A decision reversed on contact with the code

The default hotkey started as a request for a bare backtick, which decision 6 forbids: claiming a
character key makes that character untypable everywhere, forever. A double-tap was the compromise —
one press types a backtick, two start dictation.

That has an implementation fork. Either let the first press through instantly and delete both
characters when a second arrives, or hold the first press briefly and replay it if no second comes.
The first has no latency and was the recorded plan. Writing it made the cost concrete: it means
synthesising Delete into whatever window happens to be focused. In a spreadsheet that clears a cell.
The failure would be silent and would destroy the user's work.

The plan reversed to holding the keystroke for 200 ms — a delay on exactly one key, and no capacity
to damage anything. Held presses are replayed carrying a marker in `eventSourceUserData` so the tap
recognises its own output rather than catching it again in a loop. Confirming that a single backtick
still types normally was the single most important test of the phase; had the replay failed, the app
would have eaten a key off the keyboard.

### Two things the plan got wrong about the world

Decision 6 permits three shapes: modifier combos, bare function keys, and the backtick double-tap.
Function keys were the elegant one — no modifier to hold, no character sacrificed. On this Mac they
are unusable, because Logitech's keyboard software claims the F row before macOS sees it. One of the
three options is not available to the person the app is being built for.

Conflict detection was also in the Phase 3 plan, dropped during implementation, and the phase table
quietly edited to match — a scope reduction that was made invisible rather than flagged. It surfaced
when recording ⌃⌥D resized a window instead: Magnet had already claimed that combination and consumed
the keystroke before the recorder saw it. The recorder sat waiting for input that never arrived.

It is genuinely hard. macOS publishes no registry of hotkeys other applications have claimed, and
tools like Magnet, Raycast and Logitech Options grab keys through the same system-wide mechanism this
app uses. They are invisible until a keystroke does something unexpected. The gap is now written down
in `DEFERRED.md` with the three things that *are* achievable — warn on Apple's own shortcuts, offer a
"test it" step after recording, and treat a recorder that sees nothing as evidence that something
upstream ate the key.

Writing the cut down was the point. A quietly narrowed scope is worse than an unbuilt feature,
because nobody knows to miss it.

---

## 2026-08-22 — Deleting the hardest phase before building it

Phase 5 was supposed to be the heavy one: integrate whisper.cpp, ship a model downloader, keep a
460 MB file out of git, and take on the project's first external dependency. It ended up being one
of the smaller phases, because of a question asked before any of it was written.

Philip asked whether macOS already had speech-to-text built in.

It does. macOS 26 ships `SpeechAnalyzer`, an on-device engine with models the OS manages. Against
whisper.cpp it wins on nearly every axis that mattered here: no download, no C++ interop, no Swift
package that could fail to build, no large binary to gitignore, and far less code. Privacy was the
reason whisper.cpp was chosen in the first place, and that survives intact — both run locally, and
the locked decision said "on-device, nothing leaves the Mac" without naming an engine. Swapping was
a stack change, not a change of principle, which is precisely why the distinction between the two
was worth writing down back in the first session.

One thing argued against it. A locked decision says the app must learn the user's vocabulary — rare
words, names, jargon. whisper.cpp does that with an initial prompt; the older `SFSpeechRecognizer`
does it with `contextualStrings`. Whether `SpeechAnalyzer` offers an equivalent was unknown, and
guessing either way would have been dishonest.

So transcription went in behind a protocol. `Transcriber` is a handful of lines: prepare, transcribe,
a display name, and a flag saying whether vocabulary hints actually work. `AppleTranscriber` reports
that flag as **false** — not because it is known to be false, but because it is unproven, and the
Settings pane tells the user so in plain orange text rather than implying a feature works. If the
gap turns out to be real, a whisper.cpp implementation replaces one file.

The containment paid off immediately. The first build produced exactly two errors, both in that one
file, both wrong symbol names against a framework new enough that recall was unreliable. The fix was
not to guess again. The SDK on the machine ships Apple's own `.swiftinterface` for the framework, and
a single `grep` printed the truth: `bestAvailableAudioFormat` is a static on `SpeechAnalyzer` rather
than on the transcriber, and the preset is `.transcription`, not the invented `.offlineTranscription`.
Two corrections, one file, no guessing loop. The same output incidentally revealed a sibling
`DictationTranscriber` whose presets are named for this exact use case — noted for later, not adopted,
on the grounds that one unknown per phase is enough.

The first transcript, from 8.9 seconds of speech: *"I am testing this dictation app. Today is
Saturday, August 22nd at 9:03 PM."* Punctuation, capitalisation, an ordinal and a clock time, all
correct, with no post-processing and no model download.

### The other half of the evening

The code went in cleanly. Git did not.

A markdown code fence was copied into Terminal along with the command inside it, and zsh — seeing an
unmatched backtick — dropped into a `bquote>` prompt and swallowed the `git pull` whole. The build
that followed was Phase 4, unchanged, and the report was that Phase 5 "looked no different." Which
was true, and the reason was already written in the project's own handoff: *when a fix doesn't work,
confirm it's actually on the Mac before re-diagnosing.* Thirty seconds of `git log --oneline -1`
against several minutes of debugging code that was never there.

Then the pull failed for a real reason: Xcode had written the development team into `project.pbxproj`
when the signing problem was fixed the session before, and that change had never been committed. It
was the single most valuable local change in the repo, so committing it and merging was the only
acceptable move. The merge auto-resolved, opened vim for a commit message, and stranded a first-time
developer in an editor that offers no hint about how to leave.

None of that is interesting engineering. It is, though, the actual texture of building software with
tooling you have not used before, and the fixes were process, not code: set `pull.rebase false` once,
set the editor to nano, stop pasting fenced blocks. Worth recording precisely because a build journal
that only shows the clean parts describes a project that never existed.

---

## 2026-08-22 (later) — Closing questions before they cost anything

Phase 6 was short. The interesting work happened before it, in a request that is easy to skip:
resolve the open questions before starting the phase that depends on them.

Two were outstanding. One was cosmetic — a document claiming the code-signing identity stayed out of
the repo, which had quietly stopped being true when Xcode wrote the development team into the project
file. The fix was to decide rather than to patch: keep it committed, deliberately, because a fresh
clone then builds and signs with no Xcode configuration, and a wrong signature is precisely what
silently revokes Accessibility. A Team ID is an account identifier, not a credential. The document
now says so and explains the tradeoff.

The second question was load-bearing. A locked decision requires the app to learn the user's
vocabulary — names, jargon, words no general model has heard. whisper.cpp does that with an initial
prompt. When the engine was swapped for Apple's `SpeechAnalyzer`, whether an equivalent existed was
unknown, and the honest response at the time was to build transcription behind a protocol, report
`supportsVocabularyHints = false`, and say so in the UI in plain orange text.

That flag was doing real work: it was not an admission of failure, it was a refusal to promise
something unverified. But it was also a question that would eventually be answered, and answering it
late means discovering mid-phase that the engine cannot do what the design assumed.

The same technique that fixed two build errors earlier answered it in one command. Apple ships a
`.swiftinterface` for every framework in the SDK; grepping the Speech framework for "contextual"
printed `AnalysisContext.contextualStrings` and `SpeechAnalyzer.setContext` — exactly the mechanism
required — along with `SFCustomLanguageModelData`, which supports custom pronunciations and phrase
weighting and is frankly more than whisper.cpp ever offered. The flag flipped to true with evidence
behind it, the hint list is now passed through, and the decision survives intact. What deliberately
did *not* change is the claim being made: the hints reach the engine, which is true; whether they
measurably improve a rare word is untested, and both documents say so.

### Phase 6, and a test that could not have passed

Delivery itself was one file. Decision 2 asked for auto-typing plus a clipboard copy; the typing half
became ⌘V rather than synthesised characters, because a normal dictation is hundreds of key events,
visibly slow, with dropped characters a known failure at that volume — and the usual objection to
pasting, that it clobbers the clipboard, does not apply when the copy was already required.

One trap surfaced only because real text was about to flow through the system for the first time. The
app watches the keyboard with an event tap, and it was about to start posting keystrokes of its own.
A transcript containing a backtick, pasted while the user's hotkey is a backtick gesture, would have
re-triggered dictation mid-paste. The fix already existed: every event the app posts carries a marker
in `eventSourceUserData` that the tap recognises and passes through. It had been added in Phase 3 for
an unrelated reason and needed only to be shared.

The instructions written for testing the fallback were simply wrong. They asked for dictation into a
password field, expecting a "copied instead" toast. That test cannot pass, and the reason is more
interesting than the mistake: secure input does not only stop apps writing keystrokes, it stops them
reading. With a password field focused, the event tap receives nothing, the hotkey never arrives, and
**dictation cannot be started into a password field at all**. macOS closes the door rather than
letting an app knock on it. The fallback still has a reachable case — secure input switching on
mid-dictation — but the broader finding is the one worth keeping: the protection is stronger than the
code assumed, and the code assumed correctly anyway.

Seven phases in, the loop is complete. Press a key, talk, press it again, and the words appear where
you were already typing.
