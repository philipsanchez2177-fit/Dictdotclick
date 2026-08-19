//
//  DictdotclickApp.swift
//  Dictdotclick
//
//  Phase 0 — menu-bar-only app shell.
//  The app has no windows at launch: it lives entirely in the menu bar
//  (BUILD-SPEC decision 7). Everything else gets built behind this icon.
//

import SwiftUI

@main
struct DictdotclickApp: App {
    var body: some Scene {
        // MenuBarExtra is SwiftUI's native menu-bar item. The `.menu` style
        // gives a plain dropdown; later phases may switch to `.window` for
        // richer content.
        MenuBarExtra("Dictdotclick", systemImage: "mic.fill") {
            // Opens the Settings scene below. Empty until Phase 1.
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

        // Declared now so the Settings… item has somewhere to go.
        // Phase 1 replaces the placeholder with the real sidebar-tabbed,
        // Liquid Glass settings window.
        Settings {
            SettingsPlaceholderView()
        }
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.largeTitle)
            Text("Dictdotclick")
                .font(.headline)
            Text("Settings arrive in Phase 1.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 420, height: 220)
    }
}
