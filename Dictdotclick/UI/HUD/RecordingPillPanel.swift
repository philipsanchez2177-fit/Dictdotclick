//
//  RecordingPillPanel.swift
//  Dictdotclick
//
//  Phase 4 — the window the recording pill lives in.
//
//  This cannot be a SwiftUI `Window`. A normal window becomes key when it
//  appears, which would pull keyboard focus out of whatever app you were
//  typing into — the one thing a dictation HUD must never do. It also needs to
//  sit above full-screen apps, which ordinary windows do not.
//
//  So: a borderless, non-activating `NSPanel` that refuses to become key,
//  joins every Space, and floats at status-bar level. Everything here is one
//  of those requirements, not decoration.
//

import AppKit
import SwiftUI

final class RecordingPillPanel: NSPanel {
    init(content: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 64),
            // .nonactivatingPanel is the flag that stops clicking the pill
            // from making Dictdotclick the active app.
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        // Status-bar level clears normal windows and full-screen content.
        level = .statusBar
        collectionBehavior = [
            .canJoinAllSpaces,      // follows the user between Spaces
            .fullScreenAuxiliary,   // allowed over a full-screen app
            .stationary,            // doesn't slide during Mission Control
            .ignoresCycle,          // never appears in ⌘-Tab or window cycling
        ]

        // The glass is drawn by SwiftUI; the window itself must contribute
        // nothing, or a grey rectangle appears behind the capsule.
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        // A menu-bar app is never "active", so without this the panel would
        // vanish the moment the user clicked back into their real work.
        hidesOnDeactivate = false

        isMovableByWindowBackground = true
        isReleasedWhenClosed = false

        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.sizingOptions = [.preferredContentSize]
        contentView = hosting
    }

    /// The whole point. A key window receives keystrokes; this one must never
    /// take them from the app the user is dictating into.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
