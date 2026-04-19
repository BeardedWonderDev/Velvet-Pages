//
//  ScrapperViewModel.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//  Updated: April 2026 - Robust parser + Genres/Themes menu support
//

import Foundation
import Network
import SwiftSoup
import SwiftUI

// MARK: - Data Models

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
        case .light:   return (.black, .secondary, .blue, .white)
        case .sepia:   return (.black, .secondary, .brown, Color(red: 0.96, green: 0.92, blue: 0.84))
        case .night:   return (.white, Color.white.opacity(0.75), .mint, Color(red: 0.09, green: 0.10, blue: 0.14))
        case .paper:   return (.primary, .secondary, .teal, Color(red: 0.98, green: 0.97, blue: 0.94))
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

struct MenuItem: Hashable, Identifiable {
    let id = UUID()
    var name: String
    var url: String
    var count: String?          // e.g. "(8643)"
}

struct MenuSection: Hashable, Identifiable {
    let id = UUID()
    var title: String           // "Genres" or "Themes"
    var items: [MenuItem]
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
    @Published var sections: [Section] = []           // Homepage story sections
    @Published var menuSections: [MenuSection] = []   // NEW: Genres & Themes
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

    // MARK: - Loading

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

        async let storySections = fetchAndParseHTML(from: storiesURL)
        async let menuData = parseMenuSections(from: storiesURL)

        let loadedStorySections = await storySections
        let loadedMenuSections = await menuData

        if loadedStorySections.isEmpty && loadedMenuSections.isEmpty {
            loadError = "Unable to load content from the site. The page may be unavailable or the HTML structure may have changed."
            return
        }

        sections = loadedStorySections
        menuSections = loadedMenuSections
        hasLoaded = true
    }

    func fetchAndParseHTML(from urlString: String) async -> [Section] {
        guard let url = URL(string: urlString) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            return parseSectionsWithStories(html: html)
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }

    private func parseMenuSections(from urlString: String) async -> [MenuSection] {
        guard let url = URL(string: urlString) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            return parseMenuFromHTML(html: html)
        } catch {
            print("Menu fetch failed: \(error)")
            return []
        }
    }

    // MARK: - Parsers

    private func parseSectionsWithStories(html: String) -> [Section] {
        var sections: [Section] = []
        
        do {
            let doc = try SwiftSoup.parse(html)
            let sectionHeaders = try doc.select("h3.notice")
            
            for header in sectionHeaders {
                let sectionTitle = try header.text().trimmingCharacters(in: .whitespacesAndNewlines)
                var stories: [Story] = []
                
                guard let storiesList = try header.nextElementSibling()?.select("ul.stories_list").first() else {
                    continue
                }
                
                let items = try storiesList.select("li")
                
                for item in items {
                    if try item.select("a").first()?.text().lowercased().contains("more") == true {
                        continue
                    }
                    
                    let titleLink = try item.select("h4 a").first()
                    let titleRaw = try titleLink?.text() ?? ""
                    let title = trimmedTitle(titleRaw)
                    let storyURL = normalizeURL(try titleLink?.attr("href") ?? "")
                    
                    let authorLink = try item.select("h4 a").last()
                    let author = try authorLink?.text() ?? "Unknown"
                    
                    let descriptionRaw = try item.select("p").text()
                    let description = removeHtmlEntities(in: descriptionRaw)
                    
                    let strongs = try item.select("strong").array()
                    let rating = strongs.count > 0 ? try strongs[0].text() : ""
                    let timesRead = strongs.count > 1 ? try strongs[1].text() : ""
                    let postedDate = strongs.count > 2 ? try strongs[2].text() : ""
                    
                    // Clean category extraction
                    let categories = extractCategories(from: item)
                    
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
                }
            }
        } catch {
            print("Error parsing stories: \(error)")
        }
        
        print("✅ Parsed \(sections.count) story sections")
        return sections
    }

    private func parseMenuFromHTML(html: String) -> [MenuSection] {
        var menuSections: [MenuSection] = []
        
        do {
            let doc = try SwiftSoup.parse(html)
            let menuDiv = try doc.select("div#menu").first()
            guard let menu = menuDiv else { return [] }
            
            let headings = try menu.select("h2")
            
            for heading in headings {
                let sectionTitle = try heading.text().trimmingCharacters(in: .whitespacesAndNewlines)
                guard sectionTitle == "Genres" || sectionTitle == "Themes" else { continue }
                
                guard let ul = try heading.nextElementSibling(), try ul.tagName() == "ul" else { continue }
                
                let listItems = try ul.select("li")
                var menuItems: [MenuItem] = []
                
                for li in listItems {
                    if let link = try li.select("a").first() {
                        let name = try link.text().trimmingCharacters(in: .whitespacesAndNewlines)
                        let href = try link.attr("href")
                        let fullURL = normalizeURL(href)
                        
                        let fullText = try li.text()
                        let count = fullText.range(of: #"\(\d+\)"#, options: .regularExpression)
                            .map { String(fullText[$0]) }
                        
                        let item = MenuItem(name: name, url: fullURL, count: count)
                        menuItems.append(item)
                    }
                }
                
                if !menuItems.isEmpty {
                    menuSections.append(MenuSection(title: sectionTitle, items: menuItems))
                }
            }
        } catch {
            print("Error parsing menu: \(error)")
        }
        
        print("✅ Parsed \(menuSections.count) menu sections (Genres & Themes)")
        return menuSections
    }

    private func extractCategories(from item: Element) -> [String] {
        guard let lastText = try? item.textNodes().last?.text() else { return [] }
        
        return lastText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { category in
                let lower = category.lowercased()
                return !lower.contains("rated") &&
                       !lower.contains("read") &&
                       !lower.contains("posted") &&
                       !lower.contains("times") &&
                       !lower.contains("ago")
            }
    }

    // MARK: - Helpers

    func removeHtmlEntities(in text: String) -> String {
        var cleaned = text
        let replacements = [
            "&laquo;": "", "&raquo;": "", "«": "", "»": "",
            "&hellip;": "...", "&ndash;": "-", "&mdash;": "-",
            "&amp;": "&", "&#039;": "'", "&quot;": "\""
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

    private func normalizeURL(_ href: String) -> String {
        guard !href.isEmpty else { return "" }
        if href.hasPrefix("http") { return href }
        if href.hasPrefix("/") { return storiesURL + href }
        return storiesURL + "/" + href
    }

    // MARK: - Network Monitoring

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if path.status == .satisfied {
                    Task { await self?.loadSectionsIfNeeded() }
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Filtering

    var allKnownCategories: [StoryCategory] {
        let categories = sections.flatMap { $0.stories.flatMap { $0.themes } }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(categories.map(StoryCategory.init(name:)))).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func filteredStories(in section: Section) -> [Story] {
        section.stories.filter { story in
            if !storyFilterState.selectedCategories.isEmpty {
                let storySet = Set(story.themes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                if storySet.isDisjoint(with: storyFilterState.selectedCategories) { return false }
            }
            
            if !storyFilterState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let search = storyFilterState.searchText.lowercased()
                let haystack = [story.title, story.author, story.description, story.themes.joined(separator: " ")].joined(separator: " ").lowercased()
                if !haystack.contains(search) { return false }
            }
            return true
        }
    }
}
