// JournalEntryDetailView.swift
// Apin
//
// Detail screen for a single journal entry (T11): full question, full answer, a formatted
// timestamp, and manual tag entry/edit UI. Reached from `JournalListView`'s
// `NavigationLink(value: entry)` rows via the `.navigationDestination(for: JournalEntry.self)`
// modifier this view is registered against.
//
// Question/answer/timestamp remain read-only. Tags are editable: tapping "Edit Tags" switches
// into an editing mode backed by a local draft array (`draftTags`) so canceling out mid-edit
// (navigating away without tapping "Done") never partially commits — only tapping "Done" writes
// `draftTags` back onto `entry.tags` and persists via `JournalRepository.save(_:)` (constructed
// from the environment `modelContext` so the saved `entry` and the context that owns it always
// match — see `saveTags()`).
//
// See tasks/task-graph.md T11.

import ApinCore
import SwiftData
import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntry

    @Environment(\.modelContext) private var modelContext
    @State private var isEditingTags = false
    @State private var draftTags: [String] = []
    @State private var newTagText = ""
    @State private var saveErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.question)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(Self.formattedTimestamp(entry.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Text(entry.answer)
                    .font(.body)

                Divider()

                tagsSection
            }
            .padding()
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditingTags ? "Done" : "Edit Tags") {
                    toggleEditing()
                }
                .accessibilityIdentifier("journalEntryDetail.editTagsButton")
            }
        }
        .alert(
            "Couldn't Save Tags",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { isPresented in if !isPresented { saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    /// Starts (loads `entry.tags` into `draftTags`) or commits (writes `draftTags` back and
    /// saves) an edit pass, depending on `isEditingTags`'s *current* value before this toggles.
    private func toggleEditing() {
        if isEditingTags {
            entry.tags = draftTags
            Task { await saveTags() }
        } else {
            draftTags = entry.tags
            newTagText = ""
        }
        isEditingTags.toggle()
    }

    /// Persists `entry` (already updated with `draftTags` by `toggleEditing()`) through
    /// `JournalRepository.save(_:)`, per T11's acceptance criteria. Constructs the repository
    /// from `modelContext` (the same environment context `entry` was fetched through via
    /// `JournalListView`'s `@Query`) rather than a separately-constructed `ModelContainer`, so
    /// `save(_:)`'s `modelContext.insert(entry)` never sees an entry already attached to a
    /// *different* `ModelContext` instance.
    private func saveTags() async {
        let repository = SwiftDataJournalRepository(modelContext: modelContext)
        do {
            try await repository.save(entry)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func addDraftTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        newTagText = ""
        guard !trimmed.isEmpty, !draftTags.contains(trimmed) else { return }
        draftTags.append(trimmed)
    }

    private func removeDraftTag(_ tag: String) {
        draftTags.removeAll { $0 == tag }
    }

    @ViewBuilder
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            if isEditingTags {
                editableTagsView
            } else if entry.tags.isEmpty {
                Text("No tags yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(entry.tags.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var editableTagsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(draftTags, id: \.self) { tag in
                HStack {
                    Text(tag)
                        .font(.subheadline)
                    Spacer()
                    Button {
                        removeDraftTag(tag)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Remove tag \(tag)")
                }
            }

            HStack {
                TextField("New tag", text: $newTagText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("journalEntryDetail.newTagField")
                    .onSubmit { addDraftTag() }

                Button("Add") { addDraftTag() }
                    .accessibilityIdentifier("journalEntryDetail.addTagButton")
                    .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    /// Long date + short time formatting for the detail screen's timestamp, e.g.
    /// "August 10, 2026 at 3:45 PM". Split out as a static function (rather than inlined in
    /// `body`) so it's independently unit-testable — mirrors `JournalDaySection`'s pattern of
    /// keeping date logic separate from the view.
    static func formattedTimestamp(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        // `DateFormatter` doesn't infer locale/time zone from `calendar` — set them explicitly
        // so passing a fixed `calendar` (e.g. in tests) produces deterministic output.
        formatter.locale = calendar.locale ?? .current
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        JournalEntryDetailView(
            entry: JournalEntry(
                question: "What is spaced repetition?",
                answer: "A learning technique that spaces out review sessions over increasing "
                    + "intervals, timed to counteract the forgetting curve.",
                createdAt: .now
            )
        )
    }
    .modelContainer(for: JournalEntry.self, inMemory: true)
}

#Preview("With tags") {
    NavigationStack {
        JournalEntryDetailView(
            entry: JournalEntry(
                question: "What is spaced repetition?",
                answer: "A learning technique that spaces out review sessions over increasing intervals.",
                createdAt: .now,
                tags: ["learning", "memory"]
            )
        )
    }
    .modelContainer(for: JournalEntry.self, inMemory: true)
}
