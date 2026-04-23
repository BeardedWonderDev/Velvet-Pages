import Foundation
import SwiftSoup

struct CurrentSourceProvider: StorySourceProvider {
    let sourceType: SourceType = .currentSource
    private let baseURL = "https://sexstories.com"

    func inferSource(from urlString: String) -> SourceType? {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return nil }
        return host.contains("sexstories.com") ? .currentSource : nil
    }

    func search(query: String) async throws -> [LibraryItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let urlString = "\(baseURL)/?s=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return parseStoryList(html: html).stories.map { $0.unifiedItem }
    }

    func fetchWork(from urlString: String) async throws -> LibraryItem? {
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return parseStoryDetail(html: html, urlString: urlString)
    }

    func fetchChapterContent(for work: LibraryItem, chapter: Chapter) async throws -> String? {
        if let content = chapter.content, !content.isEmpty { return content }
        guard let urlString = chapter.url ?? work.metadata.sourceURL, let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return extractReadableBody(from: html)
    }

    private func parseStoryList(html: String) -> (title: String, stories: [Story]) {
        var stories: [Story] = []
        do {
            let doc = try SwiftSoup.parse(html)
            let items = try doc.select("ul.stories_list li")
            for item in items {
                let titleLink = try item.select("h4 a").first()
                let title = try titleLink?.text() ?? ""
                let url = normalizeURL(try titleLink?.attr("href") ?? "")
                let author = try item.select("h4 a").last()?.text() ?? "Unknown"
                let description = try item.select("p").text()
                let rating = try item.select("strong").first()?.text() ?? ""
                let themes = extractCategories(from: item)
                stories.append(Story(title: title, author: author, description: description, rating: rating, timesRead: "", postedDate: "", themes: themes, url: url))
            }
        } catch { }
        return ("Current Source", stories)
    }

    private func parseStoryDetail(html: String, urlString: String) -> LibraryItem? {
        let story = parseStoryList(html: html).stories.first(where: { $0.url == urlString })
            ?? parseStoryList(html: html).stories.first
        guard let story else { return nil }
        return story.unifiedItem
    }

    private func extractReadableBody(from html: String) -> String? {
        guard let doc = try? SwiftSoup.parse(html) else { return nil }
        let selectors = ["article", ".story-content", ".entry-content", ".content", "main", "body"]
        for selector in selectors {
            if let element = try? doc.select(selector).first(), let text = try? element.text(), !text.isEmpty {
                return text
            }
        }
        return nil
    }

    private func extractCategories(from item: Element) -> [String] {
        guard let lastText = item.textNodes().last?.text() else { return [] }
        return lastText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func normalizeURL(_ href: String) -> String {
        if href.hasPrefix("http") { return href }
        if href.hasPrefix("/") { return baseURL + href }
        return baseURL + "/" + href
    }
}
