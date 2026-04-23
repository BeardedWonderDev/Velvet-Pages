import Foundation

struct LibraryItem: Identifiable, Hashable, Codable {
    var id: String
    var source: SourceType
    var title: String
    var metadata: WorkMetadata
    var chapters: [Chapter]
    var isFavorite: Bool
    var lastReadProgress: Double
    var lastOpenedAt: Date?

    init(
        id: String = UUID().uuidString,
        source: SourceType,
        title: String,
        metadata: WorkMetadata,
        chapters: [Chapter] = [],
        isFavorite: Bool = false,
        lastReadProgress: Double = 0,
        lastOpenedAt: Date? = nil
    ) {
        self.id = id
        self.source = source
        self.title = title
        self.metadata = metadata
        self.chapters = chapters
        self.isFavorite = isFavorite
        self.lastReadProgress = lastReadProgress
        self.lastOpenedAt = lastOpenedAt
    }
}
