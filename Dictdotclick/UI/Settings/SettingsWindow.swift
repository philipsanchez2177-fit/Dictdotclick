//
//  SettingsWindow.swift
//  Dictdotclick
//
//  Phase 1 — the real Settings window: sidebar on the left, detail pane on
//  the right. Skeleton only; each pane's controls arrive in its own phase.
//
//  NavigationSplitView is SwiftUI's standard two-column layout. Built against
//  the macOS 26 SDK it renders its sidebar in Liquid Glass automatically —
//  glass is not hand-applied here, and shouldn't be. Over-applying it is the
//  usual mistake; the material is meant for floating controls, not for every
//  surface.
//

import SwiftUI

struct SettingsWindow: View {
    // The currently selected sidebar row. @State means SwiftUI redraws the
    // detail pane whenever this changes.
    @State private var selection: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selection) { tab in
                Label(tab.title, systemImage: tab.systemImage)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            SettingsDetail(tab: selection)
        }
        // The Settings scene has no natural size of its own, so one is set
        // here. minHeight keeps the sidebar from collapsing awkwardly.
        .frame(minWidth: 720, idealWidth: 780, minHeight: 460, idealHeight: 520)
    }
}

/// The right-hand pane. Every tab gets the same header treatment so the
/// window reads as one thing rather than four unrelated screens.
private struct SettingsDetail: View {
    let tab: SettingsTab

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tab.title)
                    .font(.title2.weight(.semibold))
                Text(tab.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // The pane itself. `switch` over the enum means the compiler
            // rejects this file if a tab is ever added without a view.
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
}

#Preview {
    SettingsWindow()
}
