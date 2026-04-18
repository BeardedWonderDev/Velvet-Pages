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
    case paragraph(String)
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

    private func parseStoryBody(html: String) -> [StoryReaderBlock] {
        do {
            let doc = try SwiftSoup.parse(html)
            let selectors = [
                "article",
                ".story-content",
                ".entry-content",
                ".content",
                "main"
            ]

            for selector in selectors {
                if let element = doc.select(selector).first() {
                    let structured = parseElement(element)
                    if !structured.isEmpty { return structured }
                }
            }

            if let body = doc.body() {
                let structured = parseElement(body)
                if !structured.isEmpty { return structured }
            }
        } catch {
            print("Story parse error: \(error)")
        }

        return []
    }

    private func parseElement(_ element: Element) -> [StoryReaderBlock] {
        var result: [StoryReaderBlock] = []

        let children = element.children()
        for child in children.array() {
            let tag = child.tagName().lowercased()
            let text = child.text().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            switch tag {
            case "h1", "h2", "h3", "h4", "h5", "h6":
                result.append(.heading(text))
            case "p":
                result.append(.paragraph(text))
            case "hr":
                result.append(.separator)
            case "div", "section", "article", "main":
                let nested = parseElement(child)
                if nested.isEmpty {
                    result.append(.paragraph(text))
                } else {
                    result.append(contentsOf: nested)
                }
            default:
                if (try? child.children())?.size() ?? 0 > 0 {
                    let nested = parseElement(child)
                    if nested.isEmpty {
                        result.append(.paragraph(text))
                    } else {
                        result.append(contentsOf: nested)
                    }
                } else {
                    result.append(.paragraph(text))
                }
            }
        }

        return collapseAdjacentParagraphs(result)
    }

    private func collapseAdjacentParagraphs(_ blocks: [StoryReaderBlock]) -> [StoryReaderBlock] {
        var output: [StoryReaderBlock] = []
        for block in blocks {
            if case .paragraph(let newText) = block,
               case .paragraph(let lastText)? = output.last {
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
            .flatMap { $0.components(separatedBy: "\n") }
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
