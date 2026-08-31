//
//  HistorySettingsView.swift
//  Dictdotclick
//
//  Phase 9 — everything dictated, and the vocabulary words the app noticed
//  recurring in it.
//
//  Two cards, same "card of rows" shape DictionarySettingsView established,
//  but neither one is editable the way a dictionary row is — there is
//  nothing here to type into, only things to approve, dismiss, or delete.
//  So rows here skip the locked/editing split entirely; that pattern exists
//  to make a text field's resting state read as "stored", and nothing on
//  this pane is ever a text field.
//
//  Suggestions sit above history, not below, because they are the one thing
//  on this pane that asks Philip to do something. History is a record to
//  glance over; a suggestion sitting under 500 history rows would never be
//  seen (decision 4 — nothing is learned without a click, but a click can
//  only happen if the suggestion is visible).
//

import SwiftUI

struct HistorySettingsView: View {
    @State private var history = TranscriptHistoryStore.shared
    @State private var suggestionStore = VocabularySuggestionStore.shared

    @State private var confirmingClearAll = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !suggestionStore.suggestions.isEmpty {
                    section("Suggestions",
                            caption: "Words that keep showing up across separate dictations and aren't in your vocabulary yet. Adding one only changes what the engine listens for next time — nothing here was typed for you.") {
                        suggestionsCard
                    }
                }

                section("History",
                        caption: "Everything you've dictated, newest first. Kept on this Mac only.") {
                    historyCard
                }

                privacyNote
            }
            .padding(24)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Suggestions

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(suggestionStore.suggestions, id: \.self) { word in
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.tint)
                        .font(.system(size: 13))
                        .frame(width: 14)

                    Text(word)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            suggestionStore.approve(word)
                        }
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Add to vocabulary")

                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            suggestionStore.dismiss(word)
                        }
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Not a word — don't ask again")
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    // MARK: - History

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                cardHeader(count: history.entries.count, noun: "dictation")

                Spacer()

                if !history.entries.isEmpty {
                    Button("Clear All", role: .destructive) {
                        confirmingClearAll = true
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }

            if history.entries.isEmpty {
                emptyLine("Nothing dictated yet. Every finished dictation will show up here.")
            }

            ForEach(history.entries) { entry in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(entry.deliveredText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        deleteButton("Remove") {
                            history.remove(id: entry.id)
                        }
                    }

                    if entry.wasProcessed {
                        Text("Heard: \(entry.heardText)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }

                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .confirmationDialog(
            "Delete all history?",
            isPresented: $confirmingClearAll,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) { history.clear() }
        } message: {
            Text("This removes every dictation on this list. It cannot be undone.")
        }
    }

    // MARK: - Pieces

    private func cardHeader(count: Int, noun: String) -> some View {
        Text(count == 1 ? "1 \(noun)" : "\(count) \(noun)s")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private var privacyNote: some View {
        Label("Stored only on this Mac, in Application Support. History is never sent anywhere and is not in the app's source repository.",
              systemImage: "lock")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func emptyLine(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
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
    HistorySettingsView().frame(width: 640, height: 620)
}
