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
