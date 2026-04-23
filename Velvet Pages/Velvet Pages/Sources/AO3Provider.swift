import Foundation

struct AO3Provider: StorySourceProvider {
    let sourceType: SourceType = .ao3

    func inferSource(from urlString: String) -> SourceType? {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return nil }
        return host.contains("archiveofourown.org") ? .ao3 : nil
    }

    func search(query: String) async throws -> [LibraryItem] { [] }

    func fetchWork(from urlString: String) async throws -> LibraryItem? { nil }

    func fetchChapterContent(for work: LibraryItem, chapter: Chapter) async throws -> String? { nil }
}
