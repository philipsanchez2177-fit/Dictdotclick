//
//  SettingsWindow.swift
//  Dictdotclick
//
//  Phase 1 — the Settings window: sidebar on the left, detail pane on the
//  right. Skeleton only; each pane's controls arrive in its own phase.
//
//  This lives in a plain `Window` scene rather than SwiftUI's `Settings`
//  scene. The Settings scene manages its own chrome and sizing and does not
//  give a NavigationSplitView room to lay out its sidebar. A Window scene is
//  an ordinary window this app fully controls — which is also what Phase 2's
//  permissions walkthrough and Phase 4's HUD will need.
//
//  Liquid Glass is not hand-applied here. Built against the macOS 26 SDK,
//  NavigationSplitView renders its own sidebar in glass. Over-applying the
//  material is the usual mistake; it is meant for floating elements, not for
//  every surface.
//

import SwiftUI

struct SettingsWindow: View {
    /// Scene identifier, used by the menu bar to open this window.
    /// Kept here so the string is written once, not typed in two places.
    static let windowID = "settings"

    /// The selected sidebar row. Optional because that is the type SwiftUI's
    /// single-selection List expects — a list can legitimately have nothing
    /// selected, so the binding has to be able to represent that.
    @State private var selection: SettingsTab? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        } detail: {
            let tab = selection ?? .general

            SettingsDetail(tab: tab)
                // The title and subtitle go in the window's own title bar
                // rather than being drawn inside the pane. macOS 26 title
                // bars are translucent and content passes underneath them,
                // so a hand-drawn header at the top of the pane ends up
                // hidden behind the chrome.
                .navigationTitle(tab.title)
                .navigationSubtitle(tab.subtitle)
        }
    }
}

/// The right-hand pane. One `switch` over the enum, so the compiler rejects
/// this file if a tab is ever added without a matching view.
private struct SettingsDetail: View {
    let tab: SettingsTab

    var body: some View {
        Group {
            switch tab {
            case .general:    GeneralSettingsView()
            case .hotkey:     HotkeySettingsView()
            case .dictionary: DictionarySettingsView()
            case .history:    HistorySettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsWindow()
        .frame(width: 780, height: 520)
}
