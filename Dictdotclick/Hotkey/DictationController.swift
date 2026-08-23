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

    /// Result of the most recent dictation. Phase 5 displays it; Phase 6
    /// types it into the focused app instead.
    private(set) var lastTranscript: String = ""

    private func transcribe(_ samples: [Float]) {
        guard !samples.isEmpty else { return }
        isTranscribing = true

        Task { [transcriber] in
            do {
                let text = try await transcriber.transcribe(
                    samples: samples,
                    sampleRate: AudioCapture.targetSampleRate,
                    hints: []          // Phase 7 supplies the dictionary
                )
                await MainActor.run {
                    self.lastTranscript = text
                    self.isTranscribing = false
                    if text.isEmpty {
                        self.lastIssue = "Nothing was recognised in that recording."
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
