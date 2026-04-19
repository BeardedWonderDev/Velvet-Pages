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

    func saveStory(
        story: Story,
        blocks: [StoryReaderBlock],
        lastScrollAnchor: String? = nil,
        lastReadProgress: Double = 0,
        isFavorite: Bool? = nil
    ) {
        guard let blocksData = try? StoryBlockCacheCoder.encode(blocks) else { return }

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
                themesCSV: story.themes.joined(separator: "|"),
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
        record.themesCSV = story.themes.joined(separator: "|")
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
