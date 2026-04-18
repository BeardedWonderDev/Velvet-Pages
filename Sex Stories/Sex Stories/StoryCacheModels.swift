import Foundation
import SwiftData

@Model
final class CachedStoryRecord {
    @Attribute(.unique) var storyID: String
    var storyURL: String
    var title: String
    var author: String
    var storyDescription: String
    var postedDate: String
    var themesCSV: String
    var blocksData: Data
    var lastUpdated: Date
    var lastScrollAnchor: String?
    var lastReadProgress: Double

    init(
        storyID: String,
        storyURL: String,
        title: String,
        author: String,
        storyDescription: String,
        postedDate: String,
        themesCSV: String,
        blocksData: Data,
        lastUpdated: Date = .now,
        lastScrollAnchor: String? = nil,
        lastReadProgress: Double = 0
    ) {
        self.storyID = storyID
        self.storyURL = storyURL
        self.title = title
        self.author = author
        self.storyDescription = storyDescription
        self.postedDate = postedDate
        self.themesCSV = themesCSV
        self.blocksData = blocksData
        self.lastUpdated = lastUpdated
        self.lastScrollAnchor = lastScrollAnchor
        self.lastReadProgress = lastReadProgress
    }
}

enum StoryBlockCacheCoder {
    static func encode(_ blocks: [StoryReaderBlock]) throws -> Data {
        try JSONEncoder().encode(blocks)
    }

    static func decode(_ data: Data) throws -> [StoryReaderBlock] {
        try JSONDecoder().decode([StoryReaderBlock].self, from: data)
    }
}

struct CachedStorySnapshot {
    let storyID: String
    let storyURL: String
    let title: String
    let author: String
    let storyDescription: String
    let postedDate: String
    let themes: [String]
    let blocks: [StoryReaderBlock]
    let lastScrollAnchor: String?
    let lastReadProgress: Double
    let lastUpdated: Date
}

extension CachedStoryRecord {
    var snapshot: CachedStorySnapshot? {
        guard let blocks = try? StoryBlockCacheCoder.decode(blocksData) else { return nil }
        return CachedStorySnapshot(
            storyID: storyID,
            storyURL: storyURL,
            title: title,
            author: author,
            storyDescription: storyDescription,
            postedDate: postedDate,
            themes: themesCSV.split(separator: "|").map(String.init),
            blocks: blocks,
            lastScrollAnchor: lastScrollAnchor,
            lastReadProgress: lastReadProgress,
            lastUpdated: lastUpdated
        )
    }
}

extension StoryReaderBlock: Codable {
    enum CodingKeys: String, CodingKey { case type, value }
    enum BlockType: String, Codable { case heading, paragraph, chapterTitle, separator }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BlockType.self, forKey: .type)
        let value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
        switch type {
        case .heading: self = .heading(value)
        case .paragraph: self = .paragraph(value)
        case .chapterTitle: self = .chapterTitle(value)
        case .separator: self = .separator
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .heading(let value):
            try container.encode(BlockType.heading, forKey: .type)
            try container.encode(value, forKey: .value)
        case .paragraph(let value):
            try container.encode(BlockType.paragraph, forKey: .type)
            try container.encode(value, forKey: .value)
        case .chapterTitle(let value):
            try container.encode(BlockType.chapterTitle, forKey: .type)
            try container.encode(value, forKey: .value)
        case .separator:
            try container.encode(BlockType.separator, forKey: .type)
        }
    }
}
