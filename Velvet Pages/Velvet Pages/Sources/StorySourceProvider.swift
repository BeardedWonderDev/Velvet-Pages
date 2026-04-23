import Foundation

protocol StorySourceProvider {
    var sourceType: SourceType { get }

    func inferSource(from urlString: String) -> SourceType?
    func search(query: String) async throws -> [LibraryItem]
    func fetchWork(from urlString: String) async throws -> LibraryItem?
    func fetchChapterContent(for work: LibraryItem, chapter: Chapter) async throws -> String?
}
