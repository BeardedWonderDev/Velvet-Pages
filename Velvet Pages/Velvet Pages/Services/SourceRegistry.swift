import Foundation

final class SourceRegistry {
    static let shared = SourceRegistry()

    let providers: [StorySourceProvider] = [CurrentSourceProvider(), AO3Provider()]

    func provider(for urlString: String) -> StorySourceProvider? {
        providers.first { $0.inferSource(from: urlString) != nil }
    }

    func sourceType(for urlString: String) -> SourceType? {
        provider(for: urlString)?.inferSource(from: urlString)
    }
}
