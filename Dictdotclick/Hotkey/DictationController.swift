//
//  DictationController.swift
//  Dictdotclick
//
//  Phase 3 — the on/off switch the hotkey flips, and the thing that owns it.
//
//  Phase 3 made this a boolean and nothing else. Phase 4 hangs the microphone
//  and the floating pill off that same switch — the sequencing worked exactly
//  as intended, because the toggle was already known to be reliable before
//  anything depended on it.
//
//  Phase 4 still throws the audio away on stop. Keeping the capture and the
//  transcriber separate means a Phase 5 failure is unambiguous: if the
//  waveform moves, the microphone is fine and the problem is Whisper.
//

import Foundation
import Observation
import AVFoundation

@Observable
final class DictationController {
    static let shared = DictationController()

    /// True between the press that starts dictation and the press that ends
    /// it. Toggle-style, not press-and-hold (BUILD-SPEC decision, the app's
    /// headline difference from Wispr Flow).
    private(set) var isListening = false

    /// The bound hotkey. Changing it re-points the live monitor immediately —
    /// no restart, no "changes take effect next launch".
    ///
    /// Assigned in `init` rather than inline, so the property initialiser and
    /// the observer block can't be parsed as one expression.
    private(set) var binding: HotkeyBinding {
        didSet {
            guard binding != oldValue else { return }
            monitor?.update(binding: binding)
            HotkeySettings(binding: binding).save()
        }
    }

    /// Why the last attempt to start dictation failed, if it did. Shown in
    /// the UI rather than logged — a hotkey that silently does nothing is the
    /// worst possible failure for this app.
    private(set) var lastIssue: String?

    /// Set when the event tap could not be created. The only realistic cause
    /// is missing Accessibility permission, so the UI uses it to point at the
    /// permissions window rather than showing a dead toggle.
    private(set) var monitorFailed = false

    @ObservationIgnored private var monitor: HotkeyMonitor?

    private init() {
        // didSet does not fire during init, which is what's wanted here:
        // loading the saved value must not immediately write it back.
        binding = HotkeySettings.load().binding
    }

    /// Warms the speech engine — permission, and the language model download
    /// if it hasn't happened. Called at launch so the first dictation isn't
    /// the thing that triggers a multi-hundred-megabyte download.
    func prepareTranscriber() {
        Task { [transcriber] in
            do {
                try await transcriber.prepare()
            } catch {
                await MainActor.run { self.lastIssue = error.localizedDescription }
            }
        }
    }

    // MARK: - Delivery (Phase 6)

    /// Puts the transcript where the user was working (decision 2).
    ///
    /// Silent on success — the words appearing is the feedback. A toast only
    /// when delivery fell back to the clipboard, because that is the case
    /// where the user has to do something and would otherwise think the app
    /// lost their dictation.
    private func deliver(_ text: String) {
        let outcome = TextDelivery.deliver(text)
        lastDelivery = outcome

        if case .clipboardOnly(let reason) = outcome {
            RecordingHUD.shared.flash(reason, systemImage: "doc.on.clipboard")
        }
    }

    /// Which engine is in use, for display. Deliberately visible in the UI:
    /// the whole reason transcription sits behind a protocol is that it may
    /// change, and a transcript should never be anonymous about its source.
    var transcriberName: String { transcriber.displayName }
    var transcriberSupportsHints: Bool { transcriber.supportsVocabularyHints }

    // MARK: - Lifecycle

    /// Starts listening for the hotkey. Safe to call repeatedly — used both at
    /// launch and after the user grants Accessibility, so the app recovers
    /// without a restart.
    func startMonitoring() {
        if monitor?.isRunning == true { return }

        let monitor = HotkeyMonitor(binding: binding) { [weak self] in
            self?.toggle()
        }
        let started = monitor.start()
        self.monitor = started ? monitor : nil
        monitorFailed = !started
    }

    func stopMonitoring() {
        stopListening()
        monitor?.stop()
        monitor = nil
    }

    // MARK: - State

    func toggle() {
        isListening ? stopListening() : startListening()
    }

    private func startListening() {
        guard !isListening else { return }
        lastIssue = nil

        // Check before starting the engine. AVAudioEngine's failure when
        // permission is missing is an opaque OSStatus; this produces a
        // sentence the user can act on instead.
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            lastIssue = "Microphone access is off. Open Permissions to turn it on."
            return
        }

        guard AudioCapture.shared.start() else {
            lastIssue = AudioCapture.shared.lastError ?? "Could not start the microphone."
            return
        }

        isListening = true
        RecordingHUD.shared.show()
    }

    /// Ends dictation. Also the path used when something other than the
    /// hotkey has to stop it — permission revoked, app quitting.
    func stopListening() {
        guard isListening else { return }
        isListening = false
        RecordingHUD.shared.hide()

        let samples = AudioCapture.shared.stop()
        capturedSecondsLastRun = Double(samples.count) / AudioCapture.targetSampleRate
        transcribe(samples)
    }

    /// Length of the most recent capture.
    private(set) var capturedSecondsLastRun: Double = 0

    // MARK: - Transcription (Phase 5)

    /// The engine. Held behind the protocol so swapping it is one line.
    @ObservationIgnored private let transcriber: Transcriber = AppleTranscriber()

    /// True while the transcriber is working. The pill stays up during this,
    /// because from the user's side dictation isn't finished until words
    /// appear.
    private(set) var isTranscribing = false

    /// Result of the most recent dictation, after the dictionary has been
    /// applied. This is what gets delivered.
    private(set) var lastTranscript: String = ""

    /// What the engine actually heard, before snippets and filler cleanup.
    ///
    /// Kept because it is the only way to tell a mishearing from a snippet
    /// that failed to match — the two look identical once the transcript is
    /// in the focused app, and they have opposite fixes (add a vocabulary
    /// word vs. correct the trigger).
    private(set) var lastHeardTranscript: String = ""

    /// True when post-processing changed the transcript, so Settings can show
    /// both versions only when there is something to compare.
    var lastTranscriptWasProcessed: Bool {
        !lastHeardTranscript.isEmpty && lastHeardTranscript != lastTranscript
    }

    /// What happened to the last transcript — pasted, or clipboard only.
    /// Kept so Settings can report it after the toast has gone.
    private(set) var lastDelivery: DeliveryOutcome?

    private func transcribe(_ samples: [Float]) {
        guard !samples.isEmpty else { return }
        isTranscribing = true

        // Read once, here, rather than inside the task: the dictionary is
        // edited on the main actor and a dictation should use the words as
        // they stood when it started, not as they stand when it finishes.
        let hints = DictionaryStore.shared.hints
        let snippets = DictionaryStore.shared.usableSnippets
        let removeFillers = AppSettings.shared.removeFillerWords

        Task { [transcriber] in
            do {
                let heard = try await transcriber.transcribe(
                    samples: samples,
                    sampleRate: AudioCapture.targetSampleRate,
                    hints: hints
                )
                let text = TranscriptPostProcessor.apply(
                    to: heard,
                    snippets: snippets,
                    removeFillers: removeFillers
                )
                await MainActor.run {
                    self.lastHeardTranscript = heard
                    self.lastTranscript = text
                    self.isTranscribing = false
                    if text.isEmpty {
                        self.lastIssue = "Nothing was recognised in that recording."
                        self.lastDelivery = nil
                    } else {
                        self.deliver(text)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isTranscribing = false
                    self.lastIssue = error.localizedDescription
                }
            }
        }
    }

    func setBinding(_ newBinding: HotkeyBinding) {
        binding = newBinding
    }
}

// MARK: - Persistence

/// What gets written to disk. A struct rather than raw values so adding a
/// setting later is a field, not a new file.
struct HotkeySettings: Codable {
    var binding: HotkeyBinding

    private static let filename = "hotkey.json"

    static func load() -> HotkeySettings {
        JSONStore.load(HotkeySettings.self, from: filename)
            ?? HotkeySettings(binding: .default)
    }

    func save() {
        JSONStore.save(self, to: Self.filename)
    }
}
