//
//  DictdotclickApp.swift
//  Dictdotclick
//
//  Menu-bar-only app shell. The app has no windows at launch: it lives
//  entirely in the menu bar (BUILD-SPEC decision 7).
//

import SwiftUI
import AppKit  // for NSApplication

@main
struct DictdotclickApp: App {
    var body: some Scene {
        // MenuBarExtra is SwiftUI's native menu-bar item. The `.menu` style
        // gives a plain dropdown; later phases may switch to `.window` for
        // richer content.
        MenuBarExtra("Dictdotclick", systemImage: "mic.fill") {
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
        // Scenes normally open when the app launches. This app must launch to
        // nothing but a menu bar icon, so this one stays closed until asked
        // for.
        .defaultLaunchBehavior(.suppressed)

        // Phase 2 — the permissions walkthrough. Its own window rather than a
        // Settings tab: it is a task with an end state ("all granted"), not a
        // set of preferences to browse, and Phases 3 and 4 will want to open
        // it directly the moment a permission is found missing.
        Window("Dictdotclick Permissions", id: PermissionsWindow.windowID) {
            PermissionsWindow()
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

    /// Shared with the permissions window, so both agree about system state.
    @State private var permissions = PermissionsModel.shared

    var body: some View {
        // Shown only when something is actually missing. A permanent
        // "Permissions" row would train the user to ignore it; a row that
        // appears only when it matters is worth reading.
        if !permissions.allGranted {
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
