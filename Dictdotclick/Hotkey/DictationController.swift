//
//  DictationController.swift
//  Dictdotclick
//
//  Phase 3 — the on/off switch the hotkey flips, and the thing that owns it.
//
//  Right now "dictation" means a boolean and nothing else. That is the whole
//  point of sequencing the hotkey before the microphone: if the indicator
//  toggles reliably from inside any app, the hardest part of the input path is
//  proven, and Phase 4 can add audio to a switch already known to work.
//

import Foundation
import Observation

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
        monitor?.stop()
        monitor = nil
    }

    // MARK: - State

    func toggle() {
        isListening.toggle()
    }

    /// Used when dictation must end for a reason other than the hotkey —
    /// permission revoked, app quitting.
    func stopListening() {
        guard isListening else { return }
        isListening = false
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
