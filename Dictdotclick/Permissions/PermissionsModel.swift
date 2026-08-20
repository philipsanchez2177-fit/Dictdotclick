//
//  PermissionsModel.swift
//  Dictdotclick
//
//  Phase 2 — reads permission state, asks for it, and keeps the UI live.
//
//  Two permissions, two completely different APIs:
//
//  * Microphone goes through AVFoundation, which reports four states and can
//    show the system prompt once.
//  * Accessibility goes through the accessibility API, which reports a plain
//    yes/no and cannot distinguish "never asked" from "refused".
//
//  Neither tells us when the answer changes. macOS sends no notification when
//  a user flips a switch in System Settings, so the only way to keep the
//  window honest is to re-check on a timer while it is open. Polling is the
//  supported approach here, not a shortcut.
//

import Foundation
import Observation
import AVFoundation
import ApplicationServices
import AppKit

@Observable
final class PermissionsModel {
    /// One shared instance. The menu bar and the walkthrough window are
    /// separate views that must agree about the same system state, and this
    /// object owns no data of its own — it only reflects what macOS reports.
    static let shared = PermissionsModel()

    private(set) var statuses: [Permission: PermissionStatus] = [:]

    /// Polling handle. Held so it can be stopped when the window closes —
    /// a menu-bar app runs all day and has no business waking up forever.
    @ObservationIgnored private var pollTimer: Timer?

    private init() {
        refresh()
    }

    // MARK: - Reading

    func status(of permission: Permission) -> PermissionStatus {
        statuses[permission] ?? .notDetermined
    }

    /// True once every permission is granted. Drives the "you're all set"
    /// state and the menu bar warning.
    var allGranted: Bool {
        Permission.allCases.allSatisfy { status(of: $0).isGranted }
    }

    var missing: [Permission] {
        Permission.allCases.filter { !status(of: $0).isGranted }
    }

    /// Re-reads both permissions from the system. Cheap; safe to call often.
    func refresh() {
        var next: [Permission: PermissionStatus] = [:]

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            next[.microphone] = .granted
        case .notDetermined:
            next[.microphone] = .notDetermined
        // `.restricted` means something outside the user's control (parental
        // controls, MDM) is blocking it. Indistinguishable from a denial from
        // where we stand, and the remedy is the same: go look in Settings.
        case .denied, .restricted:
            next[.microphone] = .denied
        @unknown default:
            next[.microphone] = .denied
        }

        // AXIsProcessTrusted() is a bare Bool: it cannot say whether the user
        // refused or was never asked. Reporting an ungranted state as
        // `.denied` is the safe reading — it routes the user to System
        // Settings, which always works, instead of to a prompt that may
        // never appear.
        next[.accessibility] = AXIsProcessTrusted() ? .granted : .denied

        if next != statuses { statuses = next }
    }

    // MARK: - Asking

    /// Triggers the system's own permission prompt, where one exists.
    ///
    /// Only useful in the `.notDetermined` state. macOS shows each prompt
    /// exactly once per app; after that this silently does nothing, which is
    /// why the UI switches to an "Open System Settings" button instead.
    func request(_ permission: Permission) {
        switch permission {
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
                // The callback arrives on an arbitrary queue; UI state has to
                // be touched on the main one.
                DispatchQueue.main.async { self?.refresh() }
            }

        case .accessibility:
            // Passing the prompt option shows Apple's "grant access?" alert
            // with a button that opens System Settings. It returns the
            // current trust value, which is almost always false here.
            let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
            refresh()
        }
    }

    /// Opens the System Settings pane for a permission, falling back to
    /// System Settings itself if the deep link is rejected — a wrong pane is
    /// a far better outcome than a button that appears to do nothing.
    func openSystemSettings(for permission: Permission) {
        if let url = permission.systemSettingsURL,
           NSWorkspace.shared.open(url) {
            return
        }
        if let fallback = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(fallback)
        }
    }

    // MARK: - Live updates

    /// Starts re-checking while the walkthrough is visible.
    ///
    /// The user grants permission in System Settings, in another app, with
    /// this window still on screen. Without polling it would keep showing a
    /// red dot after they had already done the thing it asked for — the exact
    /// moment people conclude an app is broken.
    func startPolling(every interval: TimeInterval = 1.0) {
        stopPolling()
        refresh()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        // .common keeps it firing while menus are open or a window is being
        // dragged; a default-mode timer stalls during those.
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
