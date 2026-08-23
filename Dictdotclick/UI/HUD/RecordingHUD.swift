//
//  RecordingHUD.swift
//  Dictdotclick
//
//  Phase 4 — shows and hides the pill, and remembers where the user put it.
//
//  Kept apart from the panel and the view so there is one owner of "is the
//  HUD on screen, and where". Later phases add content to the pill; none of
//  them should need to think about window lifetime again.
//

import AppKit
import SwiftUI

// Not marked @MainActor deliberately. Every call reaches here on the main
// thread already — `HotkeyMonitor` hops to main before firing, and AppKit
// would trap otherwise — and annotating it would force actor isolation onto
// `DictationController` and everything that touches it, for no behavioural
// gain under the Swift 5 language mode this project uses.
final class RecordingHUD {
    static let shared = RecordingHUD()

    private var panel: RecordingPillPanel?
    private init() {}

    // MARK: - Visibility

    func show() {
        let panel = existingOrNewPanel()
        position(panel)
        // `orderFrontRegardless` rather than `makeKeyAndOrderFront`: a
        // menu-bar app is never the active app, and the key variant would
        // both fail and risk stealing focus.
        panel.orderFrontRegardless()
    }

    func hide() {
        guard let panel else { return }
        savePosition(panel)
        panel.orderOut(nil)
    }

    private func existingOrNewPanel() -> RecordingPillPanel {
        if let panel { return panel }
        let created = RecordingPillPanel(content: RecordingPillView())
        panel = created
        return created
    }

    // MARK: - Placement

    /// Restores the remembered position, or falls back to bottom-centre of
    /// the screen the mouse is on — near where the user is working, clear of
    /// the Dock.
    private func position(_ panel: RecordingPillPanel) {
        panel.layoutIfNeeded()
        let size = panel.contentView?.fittingSize ?? NSSize(width: 280, height: 64)
        panel.setContentSize(size)

        if let saved = HUDPosition.load()?.point, isOnAVisibleScreen(saved, size: size) {
            panel.setFrameOrigin(saved)
            return
        }

        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }

        panel.setFrameOrigin(NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.minY + 90
        ))
    }

    /// A saved position can point at a monitor that is no longer attached.
    /// Without this check the pill would appear off-screen and look broken.
    private func isOnAVisibleScreen(_ origin: NSPoint, size: NSSize) -> Bool {
        let frame = NSRect(origin: origin, size: size)
        return NSScreen.screens.contains { $0.visibleFrame.intersects(frame) }
    }

    private func savePosition(_ panel: RecordingPillPanel) {
        HUDPosition(x: panel.frame.origin.x, y: panel.frame.origin.y).save()
    }
}

/// Where the user last dragged the pill.
struct HUDPosition: Codable {
    var x: CGFloat
    var y: CGFloat

    var point: NSPoint { NSPoint(x: x, y: y) }

    private static let filename = "hud-position.json"

    static func load() -> HUDPosition? {
        JSONStore.load(HUDPosition.self, from: filename)
    }

    func save() {
        JSONStore.save(self, to: Self.filename)
    }
}
