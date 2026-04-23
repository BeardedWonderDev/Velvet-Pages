//
//  LibraryView.swift
//  Sex Stories
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    @SceneStorage("selectedSectionIndex") var selectedSectionIndex: Int = -1
    @SceneStorage("showSettings") var showSettings: Bool = false
    @SceneStorage("showFilters") var showFilters: Bool = false

    private var libraryItems: [LibraryItem] {
        scrapper.filteredLibraryItems()
    }

    private var continueReadingItems: [LibraryItem] {
        libraryItems
            .filter { $0.lastReadProgress > 0 }
            .sorted {
                if $0.lastOpenedAt == $1.lastOpenedAt {
                    return $0.lastReadProgress > $1.lastReadProgress
                }
                return ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast)
            }
    }

    private var favoriteItems: [LibraryItem] {
        libraryItems
            .filter { $0.isFavorite }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if !continueReadingItems.isEmpty {
                    sectionBlock(title: "Continue Reading", subtitle: "Pick up where you left off.", accent: scrapper.accentColor.opacity(0.20)) {
                        storyCarousel(stories: continueReadingItems.prefix(6), card: continueReadingCard)
                    }
                } else {
                    emptySectionBlock(title: "Continue Reading", subtitle: "Start a story to see it here.")
                }

                if !favoriteItems.isEmpty {
                    sectionBlock(title: "Favorites", subtitle: "Saved stories for quick access.", accent: scrapper.accentColor.opacity(0.18)) {
                        storyCarousel(stories: favoriteItems.prefix(6), card: favoriteCard)
                    }
                } else {
                    emptySectionBlock(title: "Favorites", subtitle: "Tap the heart on a story to save it here.")
                }

                if !scrapper.sections.isEmpty {
                    sectionBlock(title: "Browse", subtitle: "Open a section to explore the legacy source.", accent: scrapper.primaryColor.opacity(0.10)) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                            ForEach(Array(scrapper.sections.enumerated()), id: \.offset) { index, section in
                                Button {
                                    showSettings = false
                                    selectedSectionIndex = index
                                    scrapper.activeBrowsePage = nil
                                    scrapper.storyFilterState = StoryFilterState()
                                } label: {
                                    browseCard(section: section, index: index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.top, 60)
        }
        .background(scrapper.backgroundColor.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Library")
                .font(.largeTitle.bold())
                .foregroundStyle(scrapper.primaryColor)
            Text("Your unified reading library across sources.")
                .font(.callout)
                .foregroundStyle(scrapper.secondaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filteredLibraryItems() -> [LibraryItem] {
        libraryItems.filter { item in
            if !scrapper.storyFilterState.selectedCategories.isEmpty {
                let itemTags = Set(item.metadata.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                if itemTags.isDisjoint(with: scrapper.storyFilterState.selectedCategories) { return false }
            }

            let searchText = scrapper.storyFilterState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !searchText.isEmpty {
                let search = searchText.lowercased()
                let haystack = [
                    item.title,
                    item.metadata.author,
                    item.metadata.summary,
                    item.metadata.tags.joined(separator: " "),
                    item.metadata.fandoms.joined(separator: " "),
                    item.metadata.relationships.joined(separator: " "),
                    item.metadata.characters.joined(separator: " ")
                ].joined(separator: " ").lowercased()
                if !haystack.contains(search) { return false }
            }

            if scrapper.storyFilterState.showOnlyFavorites && !item.isFavorite { return false }
            if scrapper.storyFilterState.showOnlyContinueReading && item.lastReadProgress <= 0 { return false }
            return true
        }
    }

    private func resolveStory(for item: LibraryItem) -> Story {
        Story(
            title: item.title,
            author: item.metadata.author,
            description: item.metadata.summary,
            rating: item.metadata.rating ?? "",
            timesRead: "",
            postedDate: item.metadata.lastUpdated.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? "",
            themes: item.metadata.tags,
            url: item.metadata.sourceURL ?? ""
        )
    }

    private func toggleFavorite(for item: LibraryItem) {
        guard let index = scrapper.libraryItems.firstIndex(where: { $0.id == item.id }) else { return }
        scrapper.libraryItems[index].isFavorite.toggle()
    }

    private enum CardTreatment {
        case continueReading
        case favorite
    }

    private func storyCard(item: LibraryItem, isFavorite: Bool, favoriteTint: Color, treatment: CardTreatment) -> some View {
        let progress = max(0, min(1, item.lastReadProgress))
        let cardFill: some ShapeStyle = treatment == .continueReading
            ? AnyShapeStyle(.linearGradient(
                colors: [scrapper.surfaceColor, scrapper.elevatedSurfaceColor.opacity(scrapper.selectedTheme == .night ? 0.96 : 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            : AnyShapeStyle(scrapper.mutedSurfaceColor)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(scrapper.primaryColor)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.metadata.author.isEmpty ? "Unknown author" : item.metadata.author)
                        .font(.caption)
                        .foregroundStyle(scrapper.secondaryColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    toggleFavorite(for: item)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isFavorite ? favoriteTint : scrapper.secondaryColor)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(isFavorite ? favoriteTint.opacity(0.12) : scrapper.controlFillColor))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 7) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(scrapper.primaryColor.opacity(0.10))
                        Capsule()
                            .fill(treatment == .favorite ? favoriteTint : scrapper.accentColor)
                            .frame(width: proxy.size.width * progress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(treatment == .favorite ? "Saved" : "\(Int(progress * 100))% read")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(scrapper.secondaryColor)
                    Spacer()
                    Image(systemName: treatment == .continueReading ? "arrow.right.circle.fill" : "chevron.right")
                        .foregroundStyle(treatment == .favorite ? favoriteTint : scrapper.accentColor)
                        .font(.system(size: treatment == .continueReading ? 18 : 12, weight: .semibold))
                }
            }
        }
        .padding(14)
        .frame(width: 240, height: 152, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(cardFill))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(scrapper.primaryColor.opacity(0.08), lineWidth: 1))
    }

    private func continueReadingCard(item: LibraryItem) -> some View {
        NavigationLink {
            StoryReaderView(story: resolveStory(for: item))
                .environmentObject(scrapper)
        } label: {
            storyCard(item: item, isFavorite: item.isFavorite, favoriteTint: .red, treatment: .continueReading)
        }
        .buttonStyle(.plain)
    }

    private func favoriteCard(item: LibraryItem) -> some View {
        NavigationLink {
            StoryReaderView(story: resolveStory(for: item))
                .environmentObject(scrapper)
        } label: {
            storyCard(item: item, isFavorite: true, favoriteTint: .pink, treatment: .favorite)
        }
        .buttonStyle(.plain)
    }

    private func storyCarousel<Content: View>(stories: ArraySlice<LibraryItem>, card: @escaping (LibraryItem) -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(stories), id: \.id) { item in
                    card(item)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func sectionBlock<Content: View>(title: String, subtitle: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(scrapper.primaryColor)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(scrapper.secondaryColor)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent, scrapper.surfaceColor.opacity(scrapper.selectedTheme == .night ? 0.96 : 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [scrapper.primaryColor.opacity(0.16), scrapper.primaryColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func emptySectionBlock(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(scrapper.primaryColor)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(scrapper.secondaryColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [scrapper.mutedSurfaceColor, scrapper.surfaceColor.opacity(scrapper.selectedTheme == .night ? 0.96 : 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(scrapper.primaryColor.opacity(0.08), lineWidth: 1)
        )
    }

    private func browseCard(section: Section, index: Int) -> some View {
        let symbol = ["books.vertical", "bookmark.fill", "sparkles", "square.grid.2x2.fill", "pencil.and.outline", "bookmark.circle.fill"]
        let chosen = symbol[index % symbol.count]
        let tint = [scrapper.accentColor, .pink, .purple, .blue, .orange, .green][index % 6]

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.14))
                    Image(systemName: chosen)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 38, height: 38)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(scrapper.secondaryColor)
            }

            Text(scrapper.trimmedTitle(section.title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(scrapper.primaryColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("Open section")
                .font(.caption.weight(.medium))
                .foregroundStyle(scrapper.secondaryColor)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.10), scrapper.surfaceColor.opacity(0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [tint.opacity(0.22), scrapper.primaryColor.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
