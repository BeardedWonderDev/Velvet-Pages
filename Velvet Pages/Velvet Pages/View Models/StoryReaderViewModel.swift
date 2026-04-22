//
//  StoryReaderViewModel.swift
//  Sex Stories
//

import Foundation
import CryptoKit
import SwiftSoup
import SwiftUI
import SwiftData


enum StoryReaderBlock: Hashable {
    case heading(String)
    case paragraph(String)
    case chapterTitle(String)
    case separator
    
    var stableAnchorID: String {
        switch self {
        case .heading(let text): return "heading-\(Self.stableToken(for: text))"
        case .paragraph(let text): return "paragraph-\(Self.stableToken(for: text))"
        case .chapterTitle(let text): return "chapter-\(Self.stableToken(for: text))"
        case .separator: return "separator"
        }
    }
    
    private static func stableToken(for text: String) -> String {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
        let digest = SHA256.hash(data: Data(normalized.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined().prefix(16).description
    }
}

@MainActor
final class StoryReaderViewModel: ObservableObject {
    
    @Published var story: Story
    @Published var blocks: [StoryReaderBlock] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var restoredScrollAnchor: String?
    @Published var currentScrollAnchor: String?
    
    private var cacheStore: StoryCacheStore?
    private var didLoad = false
    
    init(story: Story) {
        self.story = story
    }
    
    func configureCacheStore(_ modelContext: ModelContext) {
        if cacheStore == nil {
            cacheStore = StoryCacheStore(modelContext: modelContext)
        }
    }
    
    func loadStoryIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true

        if let snapshot = cacheStore?.loadSnapshot(for: story) {
            blocks = snapshot.blocks
            restoredScrollAnchor = snapshot.lastScrollAnchor
            currentScrollAnchor = snapshot.lastScrollAnchor
        }
        
        if story.url.isEmpty {
            if blocks.isEmpty {
                blocks = fallbackBlocks(from: story.description)
            }
            return
        }
        
        isLoading = blocks.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let parsed = try await fetchAndParseStory(from: story.url)
            guard !parsed.isEmpty else {
                if blocks.isEmpty {
                    blocks = fallbackBlocks(from: story.description)
                }
                return
            }

            blocks = parsed
            cacheStore?.saveStory(story: story, blocks: parsed, lastScrollAnchor: restoredScrollAnchor)
        } catch {
            if blocks.isEmpty {
                blocks = fallbackBlocks(from: story.description)
            }
            errorMessage = "Unable to load the story content. Showing the excerpt instead."
        }
    }
    
    func saveScrollAnchor(_ anchor: String?) {
        guard let anchor else { return }
        currentScrollAnchor = anchor
        restoredScrollAnchor = anchor
        cacheStore?.updateScrollAnchor(for: story, anchor: anchor)
    }

    func saveReadingProgress(_ progress: Double) {
        cacheStore?.updateReadingProgress(for: story, progress: progress)
    }

    func resolvedScrollAnchor(from cachedAnchor: String?) -> String? {
        guard let cachedAnchor else { return nil }
        if blocks.contains(where: { $0.stableAnchorID == cachedAnchor }) {
            return cachedAnchor
        }
        
        if cachedAnchor.hasPrefix("block-"),
           let indexString = cachedAnchor.split(separator: "-").last,
           let index = Int(indexString),
           blocks.indices.contains(index) {
            return blocks[index].stableAnchorID
        }
        
        return cachedAnchor
    }
    
    func safeAttributedMarkdown(from text: String) -> AttributedString? {
        try? AttributedString(markdown: text)
    }
    
    private func fetchAndParseStory(from urlString: String) async throws -> [StoryReaderBlock] {
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return parseStoryBody(html: html)
    }
    
    private func parseStoryBody(html: String) -> [StoryReaderBlock] {
        do {
            let doc = try SwiftSoup.parse(html)
            let blockPanels = try doc.select(".block_panel")
            if blockPanels.size() > 1 {
                let storyElement = blockPanels.get(1)
                return parseStoryElement(storyElement)
            }
            let selectors = ["article", ".story-content", ".entry-content", ".content", "main"]
            for selector in selectors {
                if let element = try doc.select(selector).first() {
                    let result = parseStoryElement(element)
                    if !result.isEmpty { return result }
                }
            }
            if let body = doc.body() {
                return parseStoryElement(body)
            }
        } catch {
            print("Parse error: \(error)")
        }
        return []
    }

    private func parseStoryElement(_ element: Element) -> [StoryReaderBlock] {
        do {
            let rawHTML = try element.html()
            let cleanedText = cleanAndNormalizeHTML(rawHTML)
            let paragraphs = cleanedText
                .components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            return paragraphs.map { paragraph in
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("Chapter ") || trimmed.lowercased().contains("chapter ") {
                    return .chapterTitle(trimmed.replacingOccurrences(of: "**", with: ""))
                } else {
                    return .paragraph(trimmed)
                }
            }
        } catch {
            print("Element parse error: \(error)")
            return []
        }
    }

    private func cleanAndNormalizeHTML(_ html: String) -> String {
        var text = html
        text = text.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<span class="italic">(.*?)</span>"#, with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<span class="bold">(.*?)</span>"#, with: "**$1**", options: .regularExpression)
        let entities: [String: String] = [
            "&ldquo;": "“", "&rdquo;": "”",
            "&lsquo;": "‘", "&rsquo;": "’",
            "&nbsp;": " ", "&amp;": "&", "&quot;": "\""
        ]
        for (key, value) in entities {
            text = text.replacingOccurrences(of: key, with: value)
        }
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackBlocks(from text: String) -> [StoryReaderBlock] {
        let parts = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.map { .paragraph($0) }
    }
}
