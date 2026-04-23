import Foundation

struct WorkMetadata: Hashable, Codable {
    var source: SourceType
    var sourceURL: String?
    var author: String
    var summary: String
    var summaryHTML: String?
    var status: String?
    var lastUpdated: Date?
    var wordCount: Int?
    var chapterCount: Int?
    var currentChapter: Int?
    var rating: String?
    var warnings: [String]
    var category: String?
    var language: String?
    var fandoms: [String]
    var relationships: [String]
    var characters: [String]
    var tags: [String]
    var stats: [String: Int]
    var extras: [String: String]

    init(
        source: SourceType,
        sourceURL: String? = nil,
        author: String = "",
        summary: String = "",
        summaryHTML: String? = nil,
        status: String? = nil,
        lastUpdated: Date? = nil,
        wordCount: Int? = nil,
        chapterCount: Int? = nil,
        currentChapter: Int? = nil,
        rating: String? = nil,
        warnings: [String] = [],
        category: String? = nil,
        language: String? = nil,
        fandoms: [String] = [],
        relationships: [String] = [],
        characters: [String] = [],
        tags: [String] = [],
        stats: [String: Int] = [:],
        extras: [String: String] = [:]
    ) {
        self.source = source
        self.sourceURL = sourceURL
        self.author = author
        self.summary = summary
        self.summaryHTML = summaryHTML
        self.status = status
        self.lastUpdated = lastUpdated
        self.wordCount = wordCount
        self.chapterCount = chapterCount
        self.currentChapter = currentChapter
        self.rating = rating
        self.warnings = warnings
        self.category = category
        self.language = language
        self.fandoms = fandoms
        self.relationships = relationships
        self.characters = characters
        self.tags = tags
        self.stats = stats
        self.extras = extras
    }
}
