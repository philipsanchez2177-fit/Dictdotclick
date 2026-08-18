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
