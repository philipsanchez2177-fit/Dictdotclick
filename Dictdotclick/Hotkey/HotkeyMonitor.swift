//
//  HotkeyMonitor.swift
//  Dictdotclick
//
//  Phase 3 — hearing the hotkey from anywhere on the Mac.
//
//  This is the one piece of the app that needs Accessibility permission. A
//  CGEvent tap sits in the system's keyboard event stream and sees key presses
//  before the app being typed into does. That is exactly the capability Apple
//  gates behind the padlock in Phase 2, and it is why there is no version of
//  this app that avoids that permission.
//
//  What it does with what it sees is narrow on purpose: compare against one
//  binding, swallow it if it matches, pass everything else through untouched.
//  No logging, no inspection, no storage of any other keystroke.
//
//  ── The double-tap problem ──────────────────────────────────────────────
//  A double-tap of a key that also types a character can be handled two ways:
//
//  1. Let the first press through immediately; if a second arrives in time,
//     start dictation and delete the two characters already typed.
//  2. Hold the first press briefly; release it if no second press arrives.
//
//  (1) has no latency but requires synthesising Delete into whatever app is
//  focused. In a spreadsheet that clears a cell; in some apps it navigates
//  back. A mistimed keystroke there destroys the user's work, and the failure
//  is silent. (2) costs `doubleTapWindow` of delay on one key and can damage
//  nothing. This implements (2). See BUILD-SPEC decision 6.
//

import Foundation
import CoreGraphics
import AppKit

final class HotkeyMonitor {
    /// How long to wait for a second press before deciding it was a single
    /// one. Long enough to be reachable, short enough not to feel broken.
    private let doubleTapWindow: TimeInterval = 0.20

    /// Marker written into events this app re-posts, so the tap can recognise
    /// its own output and pass it straight through. Without this, releasing a
    /// held keystroke would be seen again and held again, forever.
    private static let syntheticMarker: Int64 = 0x0D1C7

    private var binding: HotkeyBinding
    private let onTrigger: () -> Void

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// The swallowed first press of a possible double-tap, if one is pending.
    private var pendingTap: (keyCode: UInt16, deadline: Date)?
    private var pendingTimer: Timer?

    private(set) var isRunning = false

    init(binding: HotkeyBinding, onTrigger: @escaping () -> Void) {
        self.binding = binding
        self.onTrigger = onTrigger
    }

    deinit { stop() }

    // MARK: - Lifecycle

    /// Starts listening. Returns false when Accessibility permission is
    /// missing — the only common reason tap creation fails, and the caller's
    /// cue to send the user to the permissions window.
    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }

        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        // The callback is a C function pointer and cannot capture context, so
        // `self` is handed over as an opaque pointer and read back inside.
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
            return monitor.handle(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        isRunning = true
        return true
    }

    func stop() {
        cancelPending()
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
    }

    /// Swaps the binding without tearing the tap down.
    func update(binding newBinding: HotkeyBinding) {
        cancelPending()
        binding = newBinding
    }

    // MARK: - Event handling

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // macOS disables a tap that takes too long to respond, or when the
        // screen locks. Re-enabling is the documented recovery; without it
        // the hotkey silently stops working until the app restarts.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        // Our own re-posted keystroke coming back around. Let it through.
        if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticMarker {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags.deviceIndependent

        switch binding {
        case .combo(let wanted, let rawFlags):
            guard keyCode == wanted, flags == CGEventFlags(rawValue: rawFlags).deviceIndependent else {
                return Unmanaged.passUnretained(event)
            }
            // Fire once, on the way down. Swallow the key-up too, so the
            // focused app never sees half a keystroke.
            if type == .keyDown { fire() }
            return nil

        case .functionKey(let wanted):
            guard keyCode == wanted, flags.isEmpty else {
                return Unmanaged.passUnretained(event)
            }
            if type == .keyDown { fire() }
            return nil

        case .doubleTap(let wanted):
            return handleDoubleTap(keyCode: keyCode, flags: flags, wanted: wanted, type: type, event: event)
        }
    }

    private func handleDoubleTap(
        keyCode: UInt16, flags: CGEventFlags, wanted: UInt16,
        type: CGEventType, event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // A modified press (⇧` is ~, ⌘` cycles windows) is a different
        // keystroke and is never part of the gesture.
        guard keyCode == wanted, flags.isEmpty else {
            return Unmanaged.passUnretained(event)
        }

        // Key-ups for the watched key are swallowed alongside their key-downs
        // so a released press replays as a clean pair.
        guard type == .keyDown else { return nil }

        if let pending = pendingTap, pending.keyCode == keyCode, Date() < pending.deadline {
            // Second press inside the window: this is the gesture. The first
            // press was never delivered, so nothing needs undoing.
            cancelPending()
            fire()
            return nil
        }

        // First press. Hold it, and start the clock.
        cancelPending()
        pendingTap = (keyCode: keyCode, deadline: Date().addingTimeInterval(doubleTapWindow))
        let timer = Timer(timeInterval: doubleTapWindow, repeats: false) { [weak self] _ in
            self?.releasePendingAsSingleKeystroke()
        }
        RunLoop.main.add(timer, forMode: .common)
        pendingTimer = timer
        return nil
    }

    /// No second press arrived, so the user meant to type the character.
    /// Replay it as a real keystroke, marked so the tap ignores it.
    private func releasePendingAsSingleKeystroke() {
        guard let pending = pendingTap else { return }
        pendingTap = nil
        pendingTimer = nil

        let source = CGEventSource(stateID: .combinedSessionState)
        for isDown in [true, false] {
            guard let replay = CGEvent(keyboardEventSource: source,
                                       virtualKey: CGKeyCode(pending.keyCode),
                                       keyDown: isDown) else { continue }
            replay.setIntegerValueField(.eventSourceUserData, value: Self.syntheticMarker)
            replay.post(tap: .cgSessionEventTap)
        }
    }

    private func cancelPending() {
        pendingTimer?.invalidate()
        pendingTimer = nil
        pendingTap = nil
    }

    private func fire() {
        // The tap callback runs on the main run loop, but hop explicitly so
        // this stays true if the tap is ever moved to its own thread.
        DispatchQueue.main.async { [onTrigger] in onTrigger() }
    }
}
