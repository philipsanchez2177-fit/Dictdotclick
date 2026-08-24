//
//  TextDelivery.swift
//  Dictdotclick
//
//  Phase 6 — getting the transcript into the app you're working in.
//
//  Decision 2: type it into the focused app AND leave a copy on the
//  clipboard. Two ways to do the first half:
//
//  1. Synthesise every character as its own keystroke. Touches nothing else,
//     but a 200-word transcript is hundreds of events, it is visibly slow,
//     and dropped characters are a known failure at that volume.
//  2. Put the text on the clipboard and send ⌘V. Instant at any length.
//
//  (2) is used. Its usual objection — clobbering the clipboard — does not
//  apply here, because decision 2 already requires the copy. The clipboard is
//  written either way, so using it to deliver costs nothing extra.
//
//  Some contexts refuse synthetic keystrokes outright. That is detected up
//  front rather than discovered by the user (see `isSecureInputActive`), and
//  the clipboard copy is the fallback — which is exactly why decision 2 asked
//  for it.
//

import Foundation
import AppKit
import CoreGraphics
import Carbon.HIToolbox

enum DeliveryOutcome: Equatable {
    /// Pasted into the focused app. Also on the clipboard.
    case inserted
    /// Only copied. `reason` is shown to the user.
    case clipboardOnly(reason: String)

    var didInsert: Bool { self == .inserted }
}

enum TextDelivery {
    /// Copies `text`, then pastes it into whatever app is focused.
    ///
    /// The copy happens first and unconditionally: if anything after it goes
    /// wrong, the user still has their words and can paste by hand. Losing a
    /// transcript is the one outcome this app must never produce.
    @discardableResult
    static func deliver(_ text: String) -> DeliveryOutcome {
        guard !text.isEmpty else { return .clipboardOnly(reason: "Nothing to insert.") }

        copyToClipboard(text)

        // macOS turns on "secure input" whenever a password field has focus,
        // which blocks synthetic keystrokes system-wide. Checking beforehand
        // turns a silent no-op into a message that tells the user what to do.
        if isSecureInputActive {
            return .clipboardOnly(reason: "A password field is focused, so macOS blocks typing. Copied instead — press ⌘V.")
        }

        guard postPaste() else {
            return .clipboardOnly(reason: "Couldn't paste into that app. Copied instead — press ⌘V.")
        }

        return .inserted
    }

    // MARK: - Clipboard

    static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - Paste

    /// Synthesises ⌘V into the focused app.
    private static func postPaste() -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        else { return false }

        down.flags = .maskCommand
        up.flags = .maskCommand

        // Mark both, so this app's own hotkey tap passes them through instead
        // of inspecting them. Without it, a binding that happens to involve V
        // would be re-triggered by the app's own paste.
        for event in [down, up] {
            event.setIntegerValueField(.eventSourceUserData, value: HotkeyMonitor.syntheticMarker)
            event.post(tap: .cgSessionEventTap)
        }

        return true
    }

    // MARK: - Secure input

    /// True when some app has enabled secure input — a focused password
    /// field, most commonly. While it is on, no app can post keystrokes.
    static var isSecureInputActive: Bool {
        IsSecureEventInputEnabled()
    }
}
