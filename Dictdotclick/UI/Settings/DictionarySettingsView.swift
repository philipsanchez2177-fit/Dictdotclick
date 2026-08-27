//
//  DictionarySettingsView.swift
//  Dictdotclick
//
//  Phase 7 — the two-list editor.
//
//  The two lists look alike and are not alike, so the pane says which end of
//  the pipeline each one acts on rather than leaving the user to guess why one
//  of them fixes mishearing and the other does not.
//
//  ── Rows are locked by default ─────────────────────────────────────────
//  Edits write straight through to DictionaryStore, which saves on change.
//  A first version showed every row as a live text field and added a green
//  tick once the row was usable. That was wrong, and the reason is worth
//  keeping: a tick next to a field with a blinking cursor in it does not read
//  as *committed*. The row still looks open, so the user is still holding it.
//
//  So a row has two states, and only one of them is editable:
//
//    • **Locked** — plain text, dimmed, not a field. This is the resting
//      state, and it is what "this is stored" looks like.
//    • **Editing** — real fields, entered deliberately and left deliberately
//      by pressing Return or Done.
//
//  Newly added rows open in editing (a locked blank row would be unfillable),
//  and committing an empty row deletes it, so Return on a row added by mistake
//  is also how you cancel it. No Save button, no unsaved state — the lock is
//  about telling the truth, not about when the write happens.
//

import SwiftUI

struct DictionarySettingsView: View {
    @Bindable private var store = DictionaryStore.shared
    @State private var dictation = DictationController.shared

    /// Rows currently open for editing. Everything else is locked.
    @State private var editingIDs: Set<UUID> = []

    /// Which field holds the caret, so opening a row puts the cursor in it
    /// rather than making the user click again.
    @FocusState private var focusedID: UUID?

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
            cardHeader(count: store.vocabulary.count, noun: "word")

            if store.vocabulary.isEmpty {
                emptyLine("No words yet. Add one you keep having to fix by hand.")
            }

            ForEach($store.vocabulary) { $entry in
                if editingIDs.contains(entry.id) {
                    HStack(spacing: 8) {
                        pencilSlot()

                        TextField("Word or name", text: $entry.phrase)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedID, equals: entry.id)
                            .onSubmit { commitVocabulary(entry) }

                        doneButton { commitVocabulary(entry) }
                    }
                } else {
                    lockedRow(
                        onEdit: { beginEditing(entry.id) },
                        onDelete: { store.remove(vocabularyID: entry.id) }
                    ) {
                        Text(entry.phrase)
                            .font(.body)
                    }
                }
            }

            addButton("Add word") {
                let id = store.addVocabulary()
                beginEditing(id)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    /// Return or Done on an empty row removes it, so a row added by accident
    /// is dismissed the same way one is confirmed.
    private func commitVocabulary(_ entry: VocabularyEntry) {
        if entry.phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            store.remove(vocabularyID: entry.id)
        }
        endEditing(entry.id)
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
                    if editingIDs.contains(snippet.id) {
                        HStack(spacing: 8) {
                            pencilSlot()

                            TextField("When I say…", text: $snippet.trigger)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedID, equals: snippet.id)
                                .onSubmit { commitSnippet(snippet) }

                            doneButton { commitSnippet(snippet) }
                        }

                        // Return inserts a newline in a multi-line field, so
                        // this one cannot submit. Done is the way out, and the
                        // trigger field's Return also commits the pair.
                        TextField("…type this", text: $snippet.expansion, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2 ... 6)
                            .padding(.leading, 22)
                    } else {
                        lockedRow(
                            onEdit: { beginEditing(snippet.id) },
                            onDelete: { store.remove(snippetID: snippet.id) }
                        ) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(snippet.trigger)
                                    .font(.body)
                                Text(snippet.expansion)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(3)
                            }
                        }
                    }

                    if duplicates.contains(normalizedTrigger(snippet.trigger)) {
                        warning("Another snippet uses this trigger. Only the first will ever fire.")
                    } else if !snippet.trigger.isEmpty && snippet.expansion.isEmpty {
                        warning("This snippet does nothing until it has replacement text.")
                    }
                }
            }

            addButton("Add snippet") {
                let id = store.addSnippet()
                beginEditing(id)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    /// A snippet with no trigger at all is removed on commit. One with a
    /// trigger and no expansion is kept — it is half-finished rather than
    /// accidental, and the warning below it already says so.
    private func commitSnippet(_ snippet: Snippet) {
        if snippet.trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && snippet.expansion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            store.remove(snippetID: snippet.id)
        }
        endEditing(snippet.id)
    }

    // MARK: - Lock and unlock

    private func beginEditing(_ id: UUID) {
        editingIDs.insert(id)
        // Deferred: the field does not exist until the view rebuilds in its
        // editing state, and focus cannot land on a view that isn't there yet.
        DispatchQueue.main.async { focusedID = id }
    }

    private func endEditing(_ id: UUID) {
        focusedID = nil
        withAnimation(.easeOut(duration: 0.15)) {
            _ = editingIDs.remove(id)
        }
    }

    /// The resting state of every row: dimmed, unselectable, and visibly not
    /// a text field. Clicking anywhere on it re-opens it for editing.
    private func lockedRow<Content: View>(
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 13))
                .frame(width: 14)
                .padding(.top, 2)

            content()
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Edit")

            deleteButton("Remove", action: onDelete)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 8))
        .contentShape(.rect)
        .onTapGesture(perform: onEdit)
    }

    /// Keeps the locked and editing layouts aligned — without it, rows shift
    /// sideways as they change state.
    private func pencilSlot() -> some View {
        Image(systemName: "pencil.circle.fill")
            .foregroundStyle(.tint)
            .font(.system(size: 13))
            .frame(width: 14)
    }

    private func doneButton(action: @escaping () -> Void) -> some View {
        Button("Done", action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .keyboardShortcut(.return, modifiers: [])
    }

    private func normalizedTrigger(_ trigger: String) -> String {
        trigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Pieces

    private func cardHeader(count: Int, noun: String) -> some View {
        Text(count == 1 ? "1 \(noun)" : "\(count) \(noun)s")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
    }

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
