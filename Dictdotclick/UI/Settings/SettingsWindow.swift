//
//  SettingsWindow.swift
//  Dictdotclick
//
//  Phase 1 — the Settings window: fixed sidebar on the left, detail pane on
//  the right.
//
//  This deliberately does NOT use NavigationSplitView. That container is
//  built for navigation hierarchies that adapt to the space available: it
//  collapses, hides, and restores its columns on its own. Useful in an app
//  where the sidebar is a navigation stack; actively unhelpful here, where
//  the sidebar is four fixed rows that must always be visible. Its adaptive
//  behaviour was emptying the sidebar on resize.
//
//  A plain HStack with a fixed-width List has no adaptive behaviour to fight.
//  The layout is exactly what is written here at every window size.
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

    /// Falls back to General if the list somehow ends up with no selection,
    /// so the detail pane is never blank.
    private var tab: SettingsTab { selection ?? .general }

    var body: some View {
        HStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            // `.sidebar` is the list style that gives the translucent
            // material and rounded selection macOS sidebars use.
            .listStyle(.sidebar)
            // Fixed, not flexible. A settings sidebar has nothing to gain
            // from being resizable, and a fixed width cannot be negotiated
            // down to zero.
            .frame(width: 210)

            Divider()

            SettingsDetail(tab: tab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 700, idealWidth: 820, minHeight: 440, idealHeight: 560)
        // Title and subtitle go in the window's own title bar. macOS 26 title
        // bars are translucent and content passes underneath them, so a
        // header drawn at the top of the pane ends up hidden behind chrome.
        .navigationTitle(tab.title)
        .navigationSubtitle(tab.subtitle)
    }
}

/// The right-hand pane. One `switch` over the enum, so the compiler rejects
/// this file if a tab is ever added without a matching view.
private struct SettingsDetail: View {
    let tab: SettingsTab

    var body: some View {
        switch tab {
        case .general:    GeneralSettingsView()
        case .hotkey:     HotkeySettingsView()
        case .dictionary: DictionarySettingsView()
        case .history:    HistorySettingsView()
        }
    }
}

#Preview {
    SettingsWindow()
        .frame(width: 820, height: 560)
}
