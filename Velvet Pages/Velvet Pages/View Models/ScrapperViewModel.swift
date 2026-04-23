//
//  ScrapperViewModel.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//  Updated: April 2026 - Robust parser + Genres/Themes menu + Category Page support
//

import Foundation
import Network
import SwiftSoup
import SwiftUI

@MainActor
final class LibraryStore: ObservableObject {
    @Published var items: [LibraryItem] = []
}

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

    var sourceType: SourceType {
        SourceRegistry.shared.sourceType(for: url) ?? .currentSource
    }

    var unifiedItem: LibraryItem {
        LibraryItem(
            id: id,
            source: sourceType,
            title: title,
            metadata: WorkMetadata(
                source: sourceType,
                sourceURL: url,
                author: author,
                summary: description,
                rating: rating.isEmpty ? nil : rating,
                tags: themes
            ),
            chapters: [Chapter(number: 1, title: title, url: url, content: description)]
        )
    }
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

struct CategoryPage: Hashable {
    var title: String
    var stories: [Story]
    var currentURL: String
    var paginationURLs: [String]   // Full URLs for all pages
    var currentPage: Int = 1
}

struct BrowsePage: Hashable {
    var title: String
    var stories: [Story]
    var currentURL: String
    var rootURL: String
    var paginationURLs: [String]
    var currentPage: Int = 1
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
    @Published var menuSections: [MenuSection] = []   // Genres & Themes
    @Published var activeBrowsePage: BrowsePage?
    @Published var libraryItems: [LibraryItem] = []
    @Published var isLoading: Bool = false
    @Published var hasLoaded: Bool = false
    @Published var loadError: String?
    @Published var storyFilterState = StoryFilterState()

    private var loadInProgress = false
    private var pageCache: [String: BrowsePage] = [:]

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

    var surfaceColor: Color {
        backgroundColor.opacity(selectedTheme == .night ? 0.92 : 0.96)
    }

    var elevatedSurfaceColor: Color {
        switch selectedTheme {
        case .night:
            return Color(red: 0.14, green: 0.15, blue: 0.22)
        case .sepia:
            return Color(red: 0.98, green: 0.93, blue: 0.83)
        case .paper:
            return Color(red: 0.99, green: 0.98, blue: 0.96)
        case .light:
            return Color(uiColor: .secondarySystemBackground)
        }
    }

    var mutedSurfaceColor: Color {
        primaryColor.opacity(selectedTheme == .night ? 0.08 : 0.06)
    }

    var borderColor: Color {
        primaryColor.opacity(selectedTheme == .night ? 0.12 : 0.08)
    }

    var selectionFillColor: Color {
        accentColor.opacity(selectedTheme == .night ? 0.18 : 0.14)
    }

    var controlFillColor: Color {
        primaryColor.opacity(selectedTheme == .night ? 0.10 : 0.08)
    }

    var softShadowOpacity: Double {
        selectedTheme == .night ? 0.20 : 0.08
    }

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
    func loadLibraryIfNeeded(forceRefresh: Bool = false) async {
        guard !loadInProgress else { return }
        guard forceRefresh || libraryItems.isEmpty else { return }

        loadInProgress = true
        isLoading = true
        loadError = nil
        defer {
            isLoading = false
            loadInProgress = false
        }

        libraryItems = sections.flatMap { $0.stories }.map { $0.unifiedItem }
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

    // MARK: - New: Fetch Genre/Theme/Category Page

    func fetchCategoryPage(urlString: String) async -> CategoryPage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            return parseCategoryPage(html: html, currentURL: urlString)
        } catch {
            print("Failed to fetch category page \(urlString): \(error)")
            return nil
        }
    }

    @MainActor
    func loadBrowsePage(title: String, urlString: String) async {
        if let cached = pageCache[urlString] {
            activeBrowsePage = cached
            return
        }

        guard let page = await fetchCategoryPage(urlString: urlString) else {
            loadError = "Unable to load \(title)."
            return
        }

        let browsePage = BrowsePage(
            title: title.isEmpty ? page.title : title,
            stories: page.stories,
            currentURL: page.currentURL,
            rootURL: urlString,
            paginationURLs: page.paginationURLs,
            currentPage: page.currentPage
        )
        pageCache[urlString] = browsePage
        activeBrowsePage = browsePage
    }

    @MainActor
    func loadNextBrowsePageIfNeeded() async {
        guard var current = activeBrowsePage else { return }
        guard current.currentPage < current.paginationURLs.count else { return }

        let nextURL = current.paginationURLs[current.currentPage]
        guard !nextURL.isEmpty else { return }
        guard let nextPage = await fetchCategoryPage(urlString: nextURL) else { return }

        current.stories.append(contentsOf: nextPage.stories)
        current.currentURL = nextPage.currentURL
        current.currentPage += 1
        if current.paginationURLs.isEmpty {
            current.paginationURLs = nextPage.paginationURLs
        }

        pageCache[current.currentURL] = current
        activeBrowsePage = current
    }

    // MARK: - Parsers

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

    private func parseCategoryPage(html: String, currentURL: String) -> CategoryPage {
        let (title, stories) = parseStoryList(html: html)
        let paginationURLs = extractPaginationURLs(html: html)
        let currentPage = extractCurrentPage(from: currentURL)

        return CategoryPage(
            title: title,
            stories: stories,
            currentURL: currentURL,
            paginationURLs: paginationURLs,
            currentPage: currentPage
        )
    }

    // Reusable core parser for any story list page
    private func parseStoryList(html: String) -> (title: String, stories: [Story]) {
        var stories: [Story] = []
        var pageTitle = "Unknown"

        do {
            let doc = try SwiftSoup.parse(html)

            if let h3 = try doc.select("h3.notice").first() {
                pageTitle = try h3.text().trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let items = try doc.select("ul.stories_list li")

            for item in items {
                if try item.select("a").first()?.text().lowercased().contains("more") == true {
                    continue
                }

                let titleLink = try item.select("h4 a").first()
                let titleRaw = try titleLink?.text() ?? ""
                let title = trimmedTitle(titleRaw)
                let storyURL = normalizeURL(try titleLink?.attr("href") ?? "")

                let author = try item.select("h4 a").last()?.text() ?? "Unknown"
                let description = removeHtmlEntities(in: try item.select("p").text())

                let strongs = try item.select("strong").array()
                let rating = strongs.count > 0 ? try strongs[0].text() : ""
                let timesRead = strongs.count > 1 ? try strongs[1].text() : ""
                let postedDate = strongs.count > 2 ? try strongs[2].text() : ""

                let themes = extractCategories(from: item)

                let story = Story(
                    title: title,
                    author: author,
                    description: description,
                    rating: rating,
                    timesRead: timesRead,
                    postedDate: postedDate,
                    themes: themes,
                    url: storyURL
                )
                stories.append(story)
            }
        } catch {
            print("Error in parseStoryList: \(error)")
        }

        return (pageTitle, stories)
    }

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
                    
                    let author = try item.select("h4 a").last()?.text() ?? "Unknown"
                    let description = removeHtmlEntities(in: try item.select("p").text())
                    
                    let strongs = try item.select("strong").array()
                    let rating = strongs.count > 0 ? try strongs[0].text() : ""
                    let timesRead = strongs.count > 1 ? try strongs[1].text() : ""
                    let postedDate = strongs.count > 2 ? try strongs[2].text() : ""
                    
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
        // (Your existing menu parser - unchanged)
        var menuSections: [MenuSection] = []
        do {
            let doc = try SwiftSoup.parse(html)
            let menuDiv = try doc.select("div#menu").first()
            guard let menu = menuDiv else { return [] }
            
            let headings = try menu.select("h2")
            
            for heading in headings {
                let sectionTitle = try heading.text().trimmingCharacters(in: .whitespacesAndNewlines)
                guard sectionTitle == "Genres" || sectionTitle == "Themes" else { continue }
                
                guard let ul = try heading.nextElementSibling(), ul.tagName() == "ul" else { continue }
                
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
        guard let lastText = item.textNodes().last?.text() else { return [] }
        
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

    private func extractPaginationURLs(html: String) -> [String] {
        var urls: [String] = []
        do {
            let doc = try SwiftSoup.parse(html)
            let links = try doc.select("div.pager a.pagination")
            for link in links {
                if let href = try? link.attr("href"), !href.isEmpty {
                    urls.append(normalizeURL(href))
                }
            }
        } catch {}
        return Array(Set(urls)).sorted()
    }

    private func extractCurrentPage(from url: String) -> Int {
        if let range = url.range(of: "/p-(\\d+)", options: .regularExpression),
           let numStr = url[range].split(separator: "-").last,
           let num = Int(numStr) {
            return num
        }
        return 1
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

    // MARK: - Network & Filtering (unchanged)

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

    var allKnownCategories: [StoryCategory] {
        let sourceStories: [Story]
        if let browsePage = activeBrowsePage {
            sourceStories = browsePage.stories
        } else {
            sourceStories = sections.flatMap { $0.stories }
        }

        let categories = sourceStories
            .flatMap { $0.themes }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(Set(categories.map(StoryCategory.init(name:))))
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
