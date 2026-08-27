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
//  That is the right behaviour and it reads as broken without feedback: with
//  nothing to press and nothing acknowledging the typing, the user is left
//  inferring from behaviour whether an entry took. Reported from real use,
//  2026-08-26.
//
//  Two things fix it, and neither reintroduces an unsaved state:
//
//  * A per-row status dot — filled once a row is usable, hollow while it is
//    still incomplete. Because saving is immediate, "usable" and "stored" are
//    the same thing, so the dot can honestly mean saved.
//  * A "Saved" flash on Return. Return already committed; it just did so
//    invisibly. Now it says so.
//

import SwiftUI

struct DictionarySettingsView: View {
    @Bindable private var store = DictionaryStore.shared
    @State private var dictation = DictationController.shared

    /// Drives the brief "Saved" acknowledgement after Return.
    @State private var showSavedFlash = false

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
                        caption: "Names and jargon the engine mishears. These are given to it before it listens, so they change what it hears — not what happens afterwards. Changes save as you type; press Return to confirm.") {
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
            cardHeader(count: store.vocabulary.count, noun: "word")

            if store.vocabulary.isEmpty {
                emptyLine("No words yet. Add one you keep having to fix by hand.")
            }

            ForEach($store.vocabulary) { $entry in
                HStack(spacing: 8) {
                    statusDot(isReady: !entry.phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    TextField("Word or name", text: $entry.phrase)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(flashSaved)

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
            cardHeader(count: store.snippets.count, noun: "snippet")

            if store.snippets.isEmpty {
                emptyLine("No snippets yet. A postal address or an email signature is the usual first one.")
            }

            let duplicates = store.duplicateTriggers

            ForEach($store.snippets) { $snippet in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        // A snippet only counts as ready with both halves —
                        // a trigger with no replacement text does nothing.
                        statusDot(isReady: isReady(snippet))

                        TextField("When I say…", text: $snippet.trigger)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(flashSaved)

                        deleteButton("Remove snippet") { store.remove(snippetID: snippet.id) }
                    }

                    TextField("…type this", text: $snippet.expansion, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2 ... 6)
                        .padding(.leading, 20)   // clears the status dot column

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

    private func isReady(_ snippet: Snippet) -> Bool {
        !snippet.trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !snippet.expansion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func normalizedTrigger(_ trigger: String) -> String {
        trigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Feedback

    /// Filled dot = this row is complete, and therefore already on disk.
    /// Hollow = still missing something and doing nothing yet.
    private func statusDot(isReady: Bool) -> some View {
        Image(systemName: isReady ? "checkmark.circle.fill" : "circle.dashed")
            .foregroundStyle(isReady ? Color.green : Color.secondary.opacity(0.6))
            .font(.system(size: 13))
            .frame(width: 14)
            .help(isReady ? "Saved" : "Incomplete — this entry isn't doing anything yet")
    }

    /// Row count, and the acknowledgement that Return was heard.
    private func cardHeader(count: Int, noun: String) -> some View {
        HStack(spacing: 8) {
            Text(count == 1 ? "1 \(noun)" : "\(count) \(noun)s")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            if showSavedFlash {
                Label("Saved", systemImage: "checkmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
    }

    /// Return already committed the edit — the store saves on every change.
    /// This only makes that visible, which is the whole complaint.
    private func flashSaved() {
        withAnimation(.easeOut(duration: 0.15)) { showSavedFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeIn(duration: 0.3)) { showSavedFlash = false }
        }
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
