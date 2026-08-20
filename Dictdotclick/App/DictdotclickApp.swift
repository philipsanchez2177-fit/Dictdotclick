//
//  DictdotclickApp.swift
//  Dictdotclick
//
//  Menu-bar-only app shell. The app has no windows at launch: it lives
//  entirely in the menu bar (BUILD-SPEC decision 7).
//

import SwiftUI
import AppKit  // for NSApplication

/// Starts the hotkey listener at launch.
///
/// This has to be an AppDelegate rather than a `.task` on a Scene. Every
/// window in this app is suppressed at launch, so no window's `.task` runs
/// until the user opens something — and a hotkey that only works after you
/// visit Settings is not a hotkey. `applicationDidFinishLaunching` is the one
/// hook that reliably fires in a windowless app.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DictationController.shared.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        DictationController.shared.stopMonitoring()
    }
}

@main
struct DictdotclickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Owns the hotkey listener and the listening state. Read here so the
    /// menu bar icon can reflect it: with no audio yet, that icon is the only
    /// proof the global hotkey works from inside other apps.
    @State private var dictation = DictationController.shared

    var body: some Scene {
        MenuBarExtra("Dictdotclick", systemImage: dictation.isListening ? "mic.circle.fill" : "mic.fill") {
            MenuBarMenu()
        }
        .menuBarExtraStyle(.menu)

        // A plain window rather than SwiftUI's `Settings` scene — see the
        // note at the top of SettingsWindow.swift.
        Window("Dictdotclick Settings", id: SettingsWindow.windowID) {
            SettingsWindow()
        }
        .defaultSize(width: 820, height: 560)
        .windowResizability(.contentMinSize)
        .defaultLaunchBehavior(.suppressed)

        // Phase 2 — the permissions walkthrough. Its own window rather than a
        // Settings tab: it is a task with an end state ("all granted"), not a
        // set of preferences to browse.
        Window("Dictdotclick Permissions", id: PermissionsWindow.windowID) {
            PermissionsWindow()
                // Granting Accessibility here should make the hotkey start
                // working immediately, not after a relaunch. `startMonitoring`
                // is a no-op if the tap is already running.
                .onDisappear { dictation.startMonitoring() }
        }
        .defaultSize(width: 660, height: 560)
        .windowResizability(.contentMinSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

/// The menu bar dropdown. Split into its own view because `openWindow` is
/// read from the SwiftUI environment, which is only available inside a View.
private struct MenuBarMenu: View {
    @Environment(\.openWindow) private var openWindow
    @State private var permissions = PermissionsModel.shared
    @State private var dictation = DictationController.shared

    var body: some View {
        // Current state, stated in words. The icon carries it at a glance;
        // this is here for when a glance isn't enough.
        Text(dictation.isListening
             ? "Listening — press \(dictation.binding.displayString) to stop"
             : "Idle — press \(dictation.binding.displayString) to dictate")

        Divider()

        // Shown only when something is actually missing. A permanent
        // "Permissions" row would train the user to ignore it.
        if !permissions.allGranted || dictation.monitorFailed {
            Button("⚠︎ Permissions needed…") {
                open(PermissionsWindow.windowID)
            }
            Divider()
        }

        Button("Settings…") {
            open(SettingsWindow.windowID)
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Permissions…") {
            open(PermissionsWindow.windowID)
        }

        Divider()

        Button("Quit Dictdotclick") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    /// A menu-bar-only app is an "accessory" app: it is never the active app,
    /// so a window it opens would appear behind whatever the user was using.
    /// Activating first brings it to the front.
    private func open(_ id: String) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        openWindow(id: id)
    }
}
