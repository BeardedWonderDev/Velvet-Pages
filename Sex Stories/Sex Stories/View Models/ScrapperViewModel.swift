//
//  ScrapperViewModel.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//

import Foundation
import Network
import SwiftSoup
import SwiftUI

enum AppTheme: String, CaseIterable {
    case classicReadability
    case modernMinimalist
    case nightMode
    case natureInspired

    var colors: (primary: Color, secondary: Color, accent: Color, background: Color) {
        switch self {
        case .classicReadability:
            return (.softCream, .darkSlateGray, .oldRose, .ivory)
        case .modernMinimalist:
            return (.ghostWhite, .charcoal, .stealBlue, .aliceBlue)
        case .nightMode:
            return (.midnightBlue, .honeydew, .electricLavender, .richBlack)
        case .natureInspired:
            return (.mossGreen, .saddleBrown, .camel, .backgroundBeige)
        }
    }
}


struct Story: Hashable {
    var title: String
    var author: String
    var description: String
    var rating: String
    var timesRead: String
    var postedDate: String
    var themes: [String]
}

struct Section {
    var title: String
    var stories: [Story]
}


class ScrapperViewModel: Observable, ObservableObject {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue.global()
    private let storiesURL = "https://sexstories.com"

    @Published var isConnected: Bool = false
    @Published var sections: [Section] = []
    @Published var isLoading: Bool = false
    @Published var hasLoaded: Bool = false
    @Published var loadError: String?
    
    private var loadInProgress = false
    
    @Published var primaryColor: Color

    @Published var secondaryColor: Color

    @Published var accentColor: Color

    @Published var backgroundColor: Color
    
    init() {
        self.primaryColor = AppTheme.natureInspired.colors.primary
        self.secondaryColor = AppTheme.natureInspired.colors.secondary
        self.accentColor = AppTheme.natureInspired.colors.accent
        self.backgroundColor = AppTheme.natureInspired.colors.background
        
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    func changeTheme(to newTheme: AppTheme) {
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
    
    func removeHtmlEntities(in text: String) -> String {
        var cleanedText = text
        let htmlEntities = ["&laquo;", "&raquo;", "«", "»"] // List of entities to remove

        for entity in htmlEntities {
            cleanedText = cleanedText.replacingOccurrences(of: entity, with: "")
        }

        return cleanedText
    }

    
    func trimmedTitle(_ title: String) -> String {
        var words = title.split(separator: " ").map(String.init)

        // Check if the second word should be included
        if words.count > 1 && !words[1].starts(with: "-") && words[1] != "Sex" {
            return words[0] + " " + words[1]
        } else {
            return words[0]
        }
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                print("Network path status: \(path.status)")
                print("Is Expensive: \(path.isExpensive)") // Indicates a cellular or constrained connection
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


    private func parseSectionsWithStories(html: String) -> [Section] {
        var sections = [Section]()

        do {
            let doc = try SwiftSoup.parse(html)
            let sectionHeaders = try doc.select("h3.notice")

            guard !sectionHeaders.isEmpty else {
                print("Parse warning: no section headers found (selector: h3.notice)")
                return []
            }

            for header in sectionHeaders {
                let sectionTitle = try header.text()
                var stories = [Story]()

                let items = try header.nextElementSibling()?.select("li") ?? Elements()
                if items.isEmpty {
                    print("Parse warning: section '\(sectionTitle)' contained no story items.")
                }

                for item in items {
                    let title = try item.select("h4 a").first()?.text() ?? ""
                    let author = try item.select("h4 a").last()?.text() ?? ""
                    let rawDescription = try item.select("p").text()
                    let description = removeHtmlEntities(in: rawDescription)
                    let strongElements = try item.select("strong").array()
                    let rating = strongElements.count > 0 ? try strongElements[0].text() : ""
                    let timesRead = strongElements.count > 1 ? try strongElements[1].text() : ""
                    let postedDate = strongElements.count > 2 ? try strongElements[2].text() : ""
                    let categories = try item.ownText().components(separatedBy: ",")
                    
                    let story = Story(title: title, author: author, description: description, rating: rating, timesRead: timesRead, postedDate: postedDate, themes: categories)
                    stories.append(story)
                }

                let section = Section(title: sectionTitle, stories: stories)
                sections.append(section)
            }
        } catch {
            print("Error parsing HTML: \(error)")
        }

        return sections
    }
}
