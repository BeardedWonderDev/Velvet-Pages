//
//  LibraryView.swift
//  Sex Stories
//

import SwiftData
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    @Environment(\.modelContext) private var modelContext
    @SceneStorage("selectedSectionIndex") var selectedSectionIndex: Int = -1
    @SceneStorage("showSettings") var showSettings: Bool = false
    @SceneStorage("showFilters") var showFilters: Bool = false
    @Query(sort: [SortDescriptor(\CachedStoryRecord.lastUpdated, order: .reverse)]) private var cachedStories: [CachedStoryRecord]

    private var continueReadingStories: [CachedStorySnapshot] {
        filteredSnapshots(cachedStories.compactMap { $0.snapshot })
            .sorted {
                if $0.lastUpdated == $1.lastUpdated {
                    return $0.lastReadProgress > $1.lastReadProgress
                }
                return $0.lastUpdated > $1.lastUpdated
            }
    }

    private var favoriteStories: [CachedStorySnapshot] {
        filteredSnapshots(cachedStories.compactMap { $0.snapshot }.filter { $0.isFavorite })
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !continueReadingStories.isEmpty {
                    sectionBlock(title: "Continue Reading", subtitle: "Pick up where you left off.", accent: scrapper.accentColor.opacity(0.20)) {
                        storyCarousel(stories: continueReadingStories.prefix(6), card: continueReadingCard)
                    }
                } else {
                    emptySectionBlock(
                        title: "Continue Reading",
                        subtitle: "Start a story to see it here."
                    )
                }

                if !favoriteStories.isEmpty {
                    sectionBlock(title: "Favorites", subtitle: "Saved stories for quick access.", accent: scrapper.accentColor.opacity(0.18)) {
                        storyCarousel(stories: favoriteStories.prefix(6), card: favoriteCard)
                    }
                } else {
                    emptySectionBlock(
                        title: "Favorites",
                        subtitle: "Tap the heart on a story to save it here."
                    )
                }

                if !scrapper.sections.isEmpty {
                    sectionBlock(title: "Browse", subtitle: "Open a section to explore the library.", accent: scrapper.primaryColor.opacity(0.10)) {
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

    private func filteredSnapshots(_ stories: [CachedStorySnapshot]) -> [CachedStorySnapshot] {
        stories.filter { snapshot in
            if !scrapper.storyFilterState.selectedCategories.isEmpty {
                let storyCategories = Set(snapshot.themes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                if storyCategories.isDisjoint(with: scrapper.storyFilterState.selectedCategories) { return false }
            }
            if !scrapper.storyFilterState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let search = scrapper.storyFilterState.searchText.lowercased()
                let haystack = [snapshot.title, snapshot.author, snapshot.storyDescription, snapshot.themes.joined(separator: " ")].joined(separator: " ").lowercased()
                if !haystack.contains(search) { return false }
            }
            return true
        }
    }

    private func resolveStory(for snapshot: CachedStorySnapshot) -> Story? {
        for section in scrapper.sections {
            if let story = section.stories.first(where: { $0.id == snapshot.storyID || $0.url == snapshot.storyURL }) {
                return story
            }
        }
        return nil
    }

    private func toggleFavorite(for snapshot: CachedStorySnapshot) {
        let storyID = snapshot.storyID
        let descriptor = FetchDescriptor<CachedStoryRecord>(predicate: #Predicate { $0.storyID == storyID })
        guard let record = try? modelContext.fetch(descriptor).first else { return }
        record.isFavorite.toggle()
        record.lastUpdated = .now
        try? modelContext.save()
    }

    private func storyCard(snapshot: CachedStorySnapshot, isFavorite: Bool, favoriteTint: Color, treatment: CardTreatment) -> some View {
        let progress = max(0, min(1, snapshot.lastReadProgress))
        let titleTint: Color = scrapper.primaryColor
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
                    Text(snapshot.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(titleTint)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(snapshot.author.isEmpty ? "Unknown author" : snapshot.author)
                        .font(.caption)
                        .foregroundStyle(scrapper.secondaryColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    toggleFavorite(for: snapshot)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isFavorite ? favoriteTint : scrapper.secondaryColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isFavorite ? favoriteTint.opacity(0.12) : scrapper.controlFillColor)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
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
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardFill)
                .shadow(color: scrapper.primaryColor.opacity(scrapper.softShadowOpacity), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            scrapper.primaryColor.opacity(0.14),
                            scrapper.primaryColor.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private enum CardTreatment {
        case continueReading
        case favorite
    }

    private func continueReadingCard(snapshot: CachedStorySnapshot) -> some View {
        storyCard(snapshot: snapshot, isFavorite: false, favoriteTint: .red, treatment: .continueReading)
    }

    private func favoriteCard(snapshot: CachedStorySnapshot) -> some View {
        storyCard(snapshot: snapshot, isFavorite: true, favoriteTint: .pink, treatment: .favorite)
    }

    private func storyCarousel<Content: View>(stories: ArraySlice<CachedStorySnapshot>, card: @escaping (CachedStorySnapshot) -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(stories), id: \.storyID) { story in
                    if let resolvedStory = resolveStory(for: story) {
                        NavigationLink {
                            StoryReaderView(story: resolvedStory)
                                .environmentObject(scrapper)
                        } label: {
                            card(story)
                        }
                        .buttonStyle(.plain)
                    } else {
                        card(story)
                    }
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
                        colors: [
                            scrapper.primaryColor.opacity(0.16),
                            scrapper.primaryColor.opacity(0.05)
                        ],
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
                        colors: [
                            scrapper.mutedSurfaceColor,
                            scrapper.surfaceColor.opacity(scrapper.selectedTheme == .night ? 0.96 : 0.98)
                        ],
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
                        colors: [
                            tint.opacity(0.10),
                            scrapper.surfaceColor.opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: tint.opacity(0.12), radius: 8, x: 0, y: 4)
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
