import Foundation
import SwiftData

@MainActor
final class StoryCacheStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func cachedStory(for story: Story) -> CachedStoryRecord? {
        let storyID = story.id
        let descriptor = FetchDescriptor<CachedStoryRecord>(predicate: #Predicate { $0.storyID == storyID })
        return try? modelContext.fetch(descriptor).first
    }

    func loadSnapshot(for story: Story) -> CachedStorySnapshot? {
        cachedStory(for: story)?.snapshot
    }

    private static let filteredOutCategoryNames: Set<String> = ["rated", "read times", "posted"]

    private func normalizedCategories(from story: Story) -> [StoryCategory] {
        let cleaned = story.themes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !Self.filteredOutCategoryNames.contains($0.lowercased()) }
        return Array(Set(cleaned.map(StoryCategory.init(name:)))).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func saveStory(
        story: Story,
        blocks: [StoryReaderBlock],
        lastScrollAnchor: String? = nil,
        lastReadProgress: Double = 0,
        isFavorite: Bool? = nil
    ) {
        guard let blocksData = try? StoryBlockCacheCoder.encode(blocks) else { return }
        let categories = normalizedCategories(from: story)
        let categoriesData = (try? JSONEncoder().encode(categories)) ?? Data()
        let themesCSV = categories.map(\.name).joined(separator: "|")

        let record: CachedStoryRecord
        if let existing = cachedStory(for: story) {
            record = existing
        } else {
            record = CachedStoryRecord(
                storyID: story.id,
                storyURL: story.url,
                title: story.title,
                author: story.author,
                storyDescription: story.description,
                postedDate: story.postedDate,
                themesCSV: themesCSV,
                categoriesData: categoriesData,
                blocksData: blocksData,
                lastScrollAnchor: lastScrollAnchor,
                lastReadProgress: lastReadProgress,
                isFavorite: isFavorite ?? false
            )
            modelContext.insert(record)
            try? modelContext.save()
            return
        }

        record.storyURL = story.url
        record.title = story.title
        record.author = story.author
        record.storyDescription = story.description
        record.postedDate = story.postedDate
        record.themesCSV = themesCSV
        record.categoriesData = categoriesData
        record.blocksData = blocksData
        record.lastUpdated = .now
        if lastScrollAnchor != nil {
            record.lastScrollAnchor = lastScrollAnchor
        }
        record.lastReadProgress = max(0, min(1, lastReadProgress))
        if let isFavorite {
            record.isFavorite = isFavorite
        }

        try? modelContext.save()
    }

    func updateReadingProgress(for story: Story, progress: Double) {
        guard let record = cachedStory(for: story) else { return }
        record.lastReadProgress = max(0, min(1, progress))
        record.lastUpdated = .now
        try? modelContext.save()
    }

    func updateScrollAnchor(for story: Story, anchor: String?) {
        guard let anchor else { return }
        guard let record = cachedStory(for: story) else { return }
        record.lastScrollAnchor = anchor
        record.lastUpdated = .now
        try? modelContext.save()
    }
}
