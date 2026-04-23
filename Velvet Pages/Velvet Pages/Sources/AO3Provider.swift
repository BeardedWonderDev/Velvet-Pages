import Foundation
import SwiftSoup

struct AO3Provider: StorySourceProvider {
    let sourceType: SourceType = .ao3

    func inferSource(from urlString: String) -> SourceType? {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return nil }
        return host.contains("archiveofourown.org") ? .ao3 : nil
    }

    func search(query: String) async throws -> [LibraryItem] { [] }

    func fetchWork(from urlString: String) async throws -> LibraryItem? {
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return parseWorkPage(html: html, urlString: urlString)
    }

    func fetchChapterContent(for work: LibraryItem, chapter: Chapter) async throws -> String? {
        if let content = chapter.content, !content.isEmpty { return content }
        guard let urlString = chapter.url ?? work.metadata.sourceURL, let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return extractChapterBody(from: html)
    }

    private func parseWorkPage(html: String, urlString: String) -> LibraryItem? {
        guard let doc = try? SwiftSoup.parse(html) else { return nil }
        let title = (try? doc.select("h2.title").first()?.text()) ?? "Untitled"
        let author = (try? doc.select("h3.byline a").first()?.text()) ?? "Anonymous"
        let summary = (try? doc.select("div.summary blockquote").first()?.text()) ?? ""
        let summaryHTML = (try? doc.select("div.summary blockquote").first()?.html())
        let rating = (try? doc.select("dd.rating a").first()?.text())
        let language = (try? doc.select("dd.language").first()?.text())
        let category = (try? doc.select("dd.category a").first()?.text())
        let warnings = (try? doc.select("dd.warning a").array().compactMap { try? $0.text() }) ?? []
        let fandoms = (try? doc.select("dd.fandom a").array().compactMap { try? $0.text() }) ?? []
        let relationships = (try? doc.select("dd.relationship a").array().compactMap { try? $0.text() }) ?? []
        let characters = (try? doc.select("dd.character a").array().compactMap { try? $0.text() }) ?? []
        let tags = (try? doc.select("dd.freeform a").array().compactMap { try? $0.text() }) ?? []
        let words = Int((try? doc.select("dd.words").first()?.text().replacingOccurrences(of: ",", with: "")) ?? "")
        let chaptersText = (try? doc.select("dd.chapters").first()?.text()) ?? "1/1"
        let chapterCount = Int(chaptersText.split(separator: "/").last ?? "1")
        let chapter = Chapter(number: 1, title: title, url: urlString, content: summary)
        return LibraryItem(
            id: urlString,
            source: .ao3,
            title: title,
            metadata: WorkMetadata(
                source: .ao3,
                sourceURL: urlString,
                author: author,
                summary: summary,
                summaryHTML: summaryHTML,
                wordCount: words,
                chapterCount: chapterCount,
                rating: rating,
                warnings: warnings,
                category: category,
                language: language,
                fandoms: fandoms,
                relationships: relationships,
                characters: characters,
                tags: tags
            ),
            chapters: [chapter]
        )
    }

    private func extractChapterBody(from html: String) -> String? {
        guard let doc = try? SwiftSoup.parse(html) else { return nil }
        let selectors = ["div.userstuff", "div.chapter", "article", "body"]
        for selector in selectors {
            if let element = try? doc.select(selector).first(), let text = try? element.text(), !text.isEmpty {
                return text
            }
        }
        return nil
    }
}
