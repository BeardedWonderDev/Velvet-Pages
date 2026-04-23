//
//  BrowsePageView.swift
//  Sex Stories
//

import SwiftUI

struct BrowsePageView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    let page: BrowsePage
    @State private var scrollToTopToken = UUID()
    @State private var lastRootURL: String = ""

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    Color.clear
                        .frame(height: 1)
                        .id(scrollToTopToken)

                    LazyVStack(spacing: 12) {
                        ForEach(filteredStories(page.stories)) { story in
                            if !story.title.isEmpty {
                                NavigationLink {
                                    StoryReaderView(story: story)
                                        .environmentObject(scrapper)
                                } label: {
                                    storyCard(story: story)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if story.id == page.stories.last?.id {
                                        Task { await scrapper.loadNextBrowsePageIfNeeded() }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(scrapper.backgroundColor.ignoresSafeArea())
            .refreshable {
                if let browse = scrapper.activeBrowsePage {
                    await scrapper.loadBrowsePage(title: browse.title, urlString: browse.currentURL)
                }
            }
            .onChange(of: page.rootURL) { _, newValue in
                guard newValue != lastRootURL else { return }
                lastRootURL = newValue
                scrollToTopToken = UUID()
                DispatchQueue.main.async {
                    proxy.scrollTo(scrollToTopToken, anchor: .top)
                }
            }
            .onAppear {
                lastRootURL = page.rootURL
                proxy.scrollTo(scrollToTopToken, anchor: .top)
            }
        }
    }

    private func filteredStories(_ stories: [Story]) -> [Story] {
        stories.filter { story in
            if !scrapper.storyFilterState.selectedCategories.isEmpty {
                let storySet = Set(story.themes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                if storySet.isDisjoint(with: scrapper.storyFilterState.selectedCategories) {
                    return false
                }
            }

            if !scrapper.storyFilterState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let search = scrapper.storyFilterState.searchText.lowercased()
                let haystack = [story.title, story.author, story.description, story.themes.joined(separator: " ")]
                    .joined(separator: " ")
                    .lowercased()
                if !haystack.contains(search) {
                    return false
                }
            }

            return true
        }
    }

    private func storyCard(story: Story) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(story.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(scrapper.primaryColor)

            Text(story.description)
                .font(.callout)
                .foregroundStyle(scrapper.secondaryColor)
                .lineLimit(3)

            if !story.themes.isEmpty {
                Text(story.themes.joined(separator: ", "))
                    .font(.footnote)
                    .foregroundStyle(scrapper.secondaryColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(scrapper.mutedSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(scrapper.borderColor, lineWidth: 1)
        )
    }
}
