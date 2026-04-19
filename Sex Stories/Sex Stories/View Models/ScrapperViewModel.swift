//
//  ScrapperViewModel.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//  Updated: April 2026 - More robust parser
//

import Foundation
import Network
import SwiftSoup
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case sepia
    case night
    case paper

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "Light"
        case .sepia: return "Sepia"
        case .night: return "Night"
        case .paper: return "Paper"
        }
    }

    var colors: (primary: Color, secondary: Color, accent: Color, background: Color) {
        switch self {
        case .light:
            return (.black, .secondary, .blue, .white)
        case .sepia:
            return (.black, .secondary, .brown, Color(red: 0.96, green: 0.92, blue: 0.84))
        case .night:
            return (.white, Color.white.opacity(0.75), .mint, Color(red: 0.09, green: 0.10, blue: 0.14))
        case .paper:
            return (.primary, .secondary, .teal, Color(red: 0.98, green: 0.97, blue: 0.94))
        }
    }
}

struct Story: Hashable, Identifiable {
    var id: String { url.isEmpty ? title : url }
    var title: String
    var author: String
    var description: String
    var rating: String
    var timesRead: String
    var postedDate: String
    var themes: [String]
    var url: String
}

struct StoryFilterState: Hashable {
    var selectedCategories: Set<String> = []
    var showOnlyFavorites: Bool = false
    var showOnlyContinueReading: Bool = false
    var searchText: String = ""
}

struct Section: Hashable {
    var title: String
    var stories: [Story]
}

final class ScrapperViewModel: ObservableObject {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue.global()
    private let storiesURL = "https://sexstories.com"

    @Published var isConnected: Bool = false
    @Published var sections: [Section] = []
    @Published var isLoading: Bool = false
    @Published var hasLoaded: Bool = false
    @Published var loadError: String?
    @Published var storyFilterState = StoryFilterState()

    private var loadInProgress = false

    @AppStorage("selectedTheme") private var storedTheme: String = AppTheme.paper.rawValue
    @AppStorage("readerFontSize") private var storedFontSize: Double = 18
    @AppStorage("readerFontFamily") private var storedFontFamily: String = ReaderFontFamily.serif.rawValue
    @AppStorage("readerLineSpacing") private var storedLineSpacing: Double = 5

    @Published var selectedTheme: AppTheme = .paper {
        didSet {
            applyTheme(selectedTheme)
            storedTheme = selectedTheme.rawValue
        }
    }
    @Published var fontSize: Double = 18 {
        didSet { storedFontSize = fontSize }
    }
    @Published var readerFontFamily: ReaderFontFamily = .serif {
        didSet { storedFontFamily = readerFontFamily.rawValue }
    }
    @Published var readerLineSpacing: Double = 5 {
        didSet { storedLineSpacing = readerLineSpacing }
    }

    @Published var primaryColor: Color
    @Published var secondaryColor: Color
    @Published var accentColor: Color
    @Published var backgroundColor: Color

    init() {
        let defaults = UserDefaults.standard
        let initialTheme = AppTheme(rawValue: defaults.string(forKey: "selectedTheme") ?? AppTheme.paper.rawValue) ?? .paper
        let initialFontSize = defaults.object(forKey: "readerFontSize") as? Double ?? 18
        let initialFontFamily = ReaderFontFamily(rawValue: defaults.string(forKey: "readerFontFamily") ?? ReaderFontFamily.serif.rawValue) ?? .serif
        let initialLineSpacing = defaults.object(forKey: "readerLineSpacing") as? Double ?? 5

        self.selectedTheme = initialTheme
        self.fontSize = initialFontSize
        self.readerFontFamily = initialFontFamily
        self.readerLineSpacing = initialLineSpacing
        self.primaryColor = initialTheme.colors.primary
        self.secondaryColor = initialTheme.colors.secondary
        self.accentColor = initialTheme.colors.accent
        self.backgroundColor = initialTheme.colors.background

        monitor = NWPathMonitor()
        startMonitoring()
    }

    func changeTheme(to newTheme: AppTheme) {
        selectedTheme = newTheme
    }

    private func applyTheme(_ newTheme: AppTheme) {
        self.primaryColor = newTheme.colors.primary
        self.secondaryColor = newTheme.colors.secondary
        self.accentColor = newTheme.colors.accent
        self.backgroundColor = newTheme.colors.background
    }

    func fetchAndParseHTML(from urlString: String) async -> [Section] {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let htmlContent = String(data: data, encoding: .utf8) ?? ""
            return parseSectionsWithStories(html: htmlContent)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                print("Network request cancelled")
            } else {
                print("Network request failed: \(error)")
            }
            return []
        }
    }

    @MainActor
    func loadSectionsIfNeeded(forceRefresh: Bool = false) async {
        guard isConnected else {
            loadError = "No network connection available."
            return
        }

        guard !loadInProgress else { return }
        guard forceRefresh || (!isLoading && !hasLoaded) else { return }

        loadInProgress = true
        isLoading = true
        loadError = nil
        defer {
            isLoading = false
            loadInProgress = false
        }

        let loadedSections = await fetchStorySectionsWithRetry()
        if loadedSections.isEmpty {
            if !Task.isCancelled {
                loadError = "Unable to load stories from the site. The page may be unavailable or the HTML structure may have changed."
            }
            return
        }

        sections = loadedSections
        hasLoaded = true
    }

    private func fetchStorySectionsWithRetry() async -> [Section] {
        let attempts = 2
        for attempt in 1...attempts {
            let result = await fetchAndParseHTML(from: storiesURL)
            if !result.isEmpty {
                return result
            }

            if attempt < attempts {
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
        }
        return []
    }

    var allKnownCategories: [StoryCategory] {
        let categories = sections.flatMap { $0.stories.flatMap { $0.themes } }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !["rated", "read times", "posted"].contains($0.lowercased()) }
        return Array(Set(categories.map(StoryCategory.init(name:)))).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func filteredStories(in section: Section) -> [Story] {
        section.stories.filter { story in
            if !storyFilterState.selectedCategories.isEmpty {
                let storyCategorySet = Set(story.themes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                if storyCategorySet.isDisjoint(with: storyFilterState.selectedCategories) { return false }
            }

            if !storyFilterState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let search = storyFilterState.searchText.lowercased()
                let haystack = [story.title, story.author, story.description, story.themes.joined(separator: " ")].joined(separator: " ").lowercased()
                if !haystack.contains(search) { return false }
            }

            return true
        }
    }

    // MARK: - Improved Helpers

    func removeHtmlEntities(in text: String) -> String {
        var cleaned = text
        let replacements = [
            "&laquo;": "",
            "&raquo;": "",
            "«": "",
            "»": "",
            "&hellip;": "...",
            "&ndash;": "-",
            "&mdash;": "-",
            "&amp;": "&",
            "&#039;": "'",
            "&quot;": "\""
        ]
        
        for (entity, replacement) in replacements {
            cleaned = cleaned.replacingOccurrences(of: entity, with: replacement)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func trimmedTitle(_ title: String) -> String {
        var cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        cleaned = cleaned.replacingOccurrences(
            of: #"\s*[-–—]?\s*Sex\s*Stories\s*"#,
            with: " ",
            options: .regularExpression
        )
        
        cleaned = cleaned
            .replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-–— "))
        
        return cleaned.isEmpty ? title : cleaned
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if path.status == .satisfied {
                    Task {
                        await self?.loadSectionsIfNeeded()
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func normalizeURL(_ href: String) -> String {
        guard !href.isEmpty else { return "" }
        if href.hasPrefix("http") { return href }
        if href.hasPrefix("/") { return storiesURL + href }
        return storiesURL + "/" + href
    }

    // MARK: - Updated Robust Parser (April 2026)

    private func parseSectionsWithStories(html: String) -> [Section] {
        var sections = [Section]()
        
        do {
            let doc = try SwiftSoup.parse(html)
            let sectionHeaders = try doc.select("h3.notice")
            
            guard !sectionHeaders.isEmpty else {
                print("Parse warning: No h3.notice headers found")
                return []
            }
            
            for header in sectionHeaders {
                let sectionTitle = try header.text().trimmingCharacters(in: .whitespacesAndNewlines)
                var stories: [Story] = []
                
                // Get the stories list
                guard let storiesList = try header.nextElementSibling()?.select("ul.stories_list").first() else {
                    print("Parse warning: No stories_list ul found for section '\(sectionTitle)'")
                    continue
                }
                
                let items = try storiesList.select("li")
                
                for item in items {
                    // Skip "More..." links
                    if try item.select("a").first()?.text().lowercased().contains("more") == true {
                        continue
                    }
                    
                    // Title & URL
                    let titleLink = try item.select("h4 a").first()
                    let titleRaw = try titleLink?.text() ?? ""
                    let title = trimmedTitle(titleRaw)
                    let storyURL = normalizeURL(try titleLink?.attr("href") ?? "")
                    
                    // Author
                    let authorLink = try item.select("h4 a").last()
                    let author = try authorLink?.text() ?? "Unknown"
                    
                    // Description
                    let descriptionRaw = try item.select("p").text()
                    let description = removeHtmlEntities(in: descriptionRaw)
                    
                    // Metadata (Rated, Read, Posted)
                    let strongs = try item.select("strong").array()
                    let rating = strongs.count > 0 ? try strongs[0].text() : ""
                    let timesRead = strongs.count > 1 ? try strongs[1].text() : ""
                    let postedDate = strongs.count > 2 ? try strongs[2].text() : ""
                    
                    // Categories (comma-separated in ownText)
                    let categoryText = try item.ownText()
                    let categories = categoryText
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    let story = Story(
                        title: title,
                        author: author,
                        description: description,
                        rating: rating,
                        timesRead: timesRead,
                        postedDate: postedDate,
                        themes: categories,
                        url: storyURL
                    )
                    stories.append(story)
                }
                
                if !stories.isEmpty {
                    sections.append(Section(title: sectionTitle, stories: stories))
                } else {
                    print("Parse warning: Section '\(sectionTitle)' contained no valid stories")
                }
            }
        } catch {
            print("Error parsing HTML: \(error)")
        }
        
        print("✅ Successfully parsed \(sections.count) sections with \(sections.reduce(0) { $0 + $1.stories.count }) stories")
        return sections
    }
}
