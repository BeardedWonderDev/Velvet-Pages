//
//  StoryReaderViewModel.swift
//  Sex Stories
//

import Foundation
import SwiftSoup
import SwiftUI

enum StoryReaderTheme: String, CaseIterable {
    case light
    case sepia
    case night
    case paper
}

enum StoryReaderBlock: Hashable {
    case heading(String)
    case paragraph(String)      // Now supports markdown-style **bold** and *italic*
    case chapterTitle(String)   // New: Dedicated chapter support
    case separator
}

final class StoryReaderViewModel: ObservableObject {
    
    @Published var story: Story
    @Published var blocks: [StoryReaderBlock] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var readerTheme: StoryReaderTheme = .paper {
        didSet { applyTheme() }
    }
    @Published var fontSize: Double = 18 {
        didSet { readerFont = .system(size: fontSize, weight: .regular, design: .serif) }
    }
    @Published var lineSpacing: Double = 1.4
    @Published var readerFont: Font = .system(size: 18, weight: .regular, design: .serif)
    @Published var readerBackground: Color = .white
    @Published var readerTextColor: Color = .primary
    
    private var didLoad = false
    
    init(story: Story) {
        self.story = story
        self.readerFont = .system(size: fontSize, weight: .regular, design: .serif)
        applyTheme()
    }
    
    @MainActor
    func loadStoryIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        
        if story.url.isEmpty {
            blocks = fallbackBlocks(from: story.description)
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let parsed = try await fetchAndParseStory(from: story.url)
            if parsed.isEmpty {
                blocks = fallbackBlocks(from: story.description)
            } else {
                blocks = parsed
            }
        } catch {
            errorMessage = "Unable to load the story content. Showing the excerpt instead."
            blocks = fallbackBlocks(from: story.description)
        }
    }
    
    private func fetchAndParseStory(from urlString: String) async throws -> [StoryReaderBlock] {
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return parseStoryBody(html: html)
    }
    
    // MARK: - Enhanced Parser for sexstories.com / xnxx stories

    private func parseStoryBody(html: String) -> [StoryReaderBlock] {
        do {
            let doc = try SwiftSoup.parse(html)
            
            // Target the exact story content (second .block_panel on sexstories.com)
            let blockPanels = try doc.select(".block_panel")
            if blockPanels.size() > 1 {
                let storyElement = blockPanels.get(1)
                return parseStoryElement(storyElement)
            }
            
            // Fallbacks
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
            
            // Split on double newlines → each becomes a proper paragraph
            let paragraphs = cleanedText
                .components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            var blocks: [StoryReaderBlock] = []
            
            for paragraph in paragraphs {
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Only very obvious Chapter markers become chapterTitle (still useful)
                if trimmed.hasPrefix("Chapter ") || trimmed.lowercased().contains("chapter ") {
                    blocks.append(.chapterTitle(trimmed.replacingOccurrences(of: "**", with: "")))
                }
                // Everything else (including dialogue, quotes, etc.) is a normal paragraph
                else {
                    blocks.append(.paragraph(trimmed))
                }
            }
            
            return blocks
        } catch {
            print("Element parse error: \(error)")
            return []
        }
    }

    private func cleanAndNormalizeHTML(_ html: String) -> String {
        var text = html
        
        // ── Convert ALL <br> tags into proper newlines ──
        text = text.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
        
        // ── Convert formatting spans to markdown ──
        text = text.replacingOccurrences(of: #"<span class="italic">(.*?)</span>"#, with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<span class="bold">(.*?)</span>"#, with: "**$1**", options: .regularExpression)
        
        // ── Fix common HTML entities (quotes, etc.) ──
        let entities: [String: String] = [
            "&ldquo;": "“", "&rdquo;": "”",
            "&lsquo;": "‘", "&rsquo;": "’",
            "&nbsp;": " ", "&amp;": "&", "&quot;": "\""
        ]
        for (key, value) in entities {
            text = text.replacingOccurrences(of: key, with: value)
        }
        
        // ── Remove any leftover HTML tags ──
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // ── Clean up whitespace ──
        text = text.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n\n", options: .regularExpression)
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func collapseAdjacentParagraphs(_ blocks: [StoryReaderBlock]) -> [StoryReaderBlock] {
        var output: [StoryReaderBlock] = []
        
        for block in blocks {
            if case .paragraph(let newText) = block,
               case .paragraph(let lastText) = output.last {
                output.removeLast()
                output.append(.paragraph(lastText + "\n\n" + newText))
            } else {
                output.append(block)
            }
        }
        return output
    }
    
    private func fallbackBlocks(from text: String) -> [StoryReaderBlock] {
        let parts = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return parts.map { .paragraph($0) }
    }
    
    private func applyTheme() {
        switch readerTheme {
        case .light:
            readerBackground = .white
            readerTextColor = .black
        case .sepia:
            readerBackground = Color(red: 0.96, green: 0.92, blue: 0.84)
            readerTextColor = .black
        case .night:
            readerBackground = Color(red: 0.09, green: 0.10, blue: 0.14)
            readerTextColor = .white
        case .paper:
            readerBackground = Color(red: 0.98, green: 0.97, blue: 0.94)
            readerTextColor = .primary
        }
    }
}
