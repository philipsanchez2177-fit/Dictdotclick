//
//  DictionarySettingsView.swift
//  Dictdotclick
//
//  Phase 7 — the two-list editor.
//
//  The two lists look alike and are not alike, so the pane says which end of
//  the pipeline each one acts on rather than leaving the user to guess why
//  one of them fixes mishearing and the other does not.
//
//  Edits write straight through to DictionaryStore, which saves on change.
//  There is no Save button and no unsaved state to lose.
//

import SwiftUI

struct DictionarySettingsView: View {
    @Bindable private var store = DictionaryStore.shared
    @State private var dictation = DictationController.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !dictation.transcriberSupportsHints {
                    Label("This engine ignores vocabulary hints. Snippets still work.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                section("Vocabulary",
                        caption: "Names and jargon the engine mishears. These are given to it before it listens, so they change what it hears — not what happens afterwards.") {
                    vocabularyCard
                }

                section("Snippets",
                        caption: "Say the trigger, get the text. Applied to the finished transcript. Every trigger is also added to the vocabulary automatically — a phrase heard wrong can never be replaced.") {
                    snippetsCard
                }

                privacyNote
            }
            .padding(24)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Vocabulary

    private var vocabularyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.vocabulary.isEmpty {
                emptyLine("No words yet. Add one you keep having to fix by hand.")
            }

            ForEach($store.vocabulary) { $entry in
                HStack(spacing: 8) {
                    TextField("Word or name", text: $entry.phrase)
                        .textFieldStyle(.roundedBorder)
                    deleteButton("Remove word") { store.remove(vocabularyID: entry.id) }
                }
            }

            addButton("Add word") { store.addVocabulary() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    // MARK: - Snippets

    private var snippetsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if store.snippets.isEmpty {
                emptyLine("No snippets yet. A postal address or an email signature is the usual first one.")
            }

            let duplicates = store.duplicateTriggers

            ForEach($store.snippets) { $snippet in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("When I say…", text: $snippet.trigger)
                            .textFieldStyle(.roundedBorder)
                        deleteButton("Remove snippet") { store.remove(snippetID: snippet.id) }
                    }

                    TextField("…type this", text: $snippet.expansion, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2 ... 6)

                    if duplicates.contains(normalizedTrigger(snippet.trigger)) {
                        warning("Another snippet uses this trigger. Only the first will ever fire.")
                    } else if !snippet.trigger.isEmpty && snippet.expansion.isEmpty {
                        warning("This snippet does nothing until it has replacement text.")
                    }
                }
            }

            addButton("Add snippet") { store.addSnippet() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func normalizedTrigger(_ trigger: String) -> String {
        trigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Pieces

    private var privacyNote: some View {
        Label("Stored only on this Mac, in Application Support. Snippets are never sent anywhere and are not in the app's source repository.",
              systemImage: "lock")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func warning(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.caption)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func emptyLine(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func addButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "plus")
        }
        .buttonStyle(.borderless)
        .padding(.top, 2)
    }

    private func deleteButton(_ help: String, action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "minus.circle")
        }
        .buttonStyle(.borderless)
        .help(help)
    }

    private func section<Content: View>(
        _ title: String,
        caption: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
    }
}

#Preview {
    DictionarySettingsView().frame(width: 640, height: 620)
}
