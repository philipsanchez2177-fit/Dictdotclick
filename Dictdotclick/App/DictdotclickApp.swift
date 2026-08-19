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
        .defaultSize(width: 780, height: 520)
        .windowResizability(.contentMinSize)
        // Scenes normally open when the app launches. This app must launch to
        // nothing but a menu bar icon, so this one stays closed until asked
        // for.
        .defaultLaunchBehavior(.suppressed)
    }
}

/// The menu bar dropdown. Split into its own view because `openWindow` is
/// read from the SwiftUI environment, which is only available inside a View.
private struct MenuBarMenu: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Settings…") {
            // A menu-bar-only app is an "accessory" app: it is never the
            // active app, so a window it opens would appear behind whatever
            // the user was using. Activating first brings it to the front.
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: SettingsWindow.windowID)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Dictdotclick") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
