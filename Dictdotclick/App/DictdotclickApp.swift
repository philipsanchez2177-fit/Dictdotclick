//
//  DictdotclickApp.swift
//  Dictdotclick
//
//  Menu-bar-only app shell. The app has no windows at launch: it lives
//  entirely in the menu bar (BUILD-SPEC decision 7).
//
//  Phase 1 replaced the Settings placeholder with the real sidebar-tabbed
//  window in UI/Settings/.
//

import SwiftUI
import AppKit  // for NSApplication.shared.terminate

@main
struct DictdotclickApp: App {
    var body: some Scene {
        // MenuBarExtra is SwiftUI's native menu-bar item. The `.menu` style
        // gives a plain dropdown; later phases may switch to `.window` for
        // richer content.
        MenuBarExtra("Dictdotclick", systemImage: "mic.fill") {
            // SettingsLink opens the Settings scene below. It is the only
            // supported way to open that scene from a menu.
            SettingsLink {
                Text("Settings…")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Dictdotclick") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsWindow()
        }
    }
}
