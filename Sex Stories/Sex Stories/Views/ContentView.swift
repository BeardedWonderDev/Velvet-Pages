//
//  ContentView.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    @SceneStorage("showFilters") var showFilters: Bool = false
    let section: Section?

    init(section: Section? = nil) {
        self.section = section
    }

    var body: some View {
        Group {
            if scrapper.isConnected {
                if scrapper.isLoading && scrapper.sections.isEmpty {
                    loadingState
                } else if let loadError = scrapper.loadError {
                    errorState(message: loadError)
                } else if let browsePage = scrapper.activeBrowsePage {
                    BrowsePageView(page: browsePage)
                        .environmentObject(scrapper)
                        .id(browsePage.currentURL)
                } else if let section {
                    SectionView(section: section)
                        .environmentObject(scrapper)
                } else if let firstSection = scrapper.sections.first {
                    SectionView(section: firstSection)
                        .environmentObject(scrapper)
                } else {
                    emptyState
                }
            } else {
                errorState(message: "No Network Available")
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading stories...")
                .font(.footnote)
                .foregroundStyle(scrapper.secondaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(scrapper.backgroundColor.ignoresSafeArea())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(scrapper.accentColor)
            Text("No stories available")
                .font(.headline)
                .foregroundStyle(scrapper.primaryColor)
            Text("Try refreshing or check back once content loads.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(scrapper.secondaryColor)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(scrapper.backgroundColor.ignoresSafeArea())
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(scrapper.primaryColor)
            Button("Try Again") {
                Task { await scrapper.loadSectionsIfNeeded(forceRefresh: true) }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(scrapper.backgroundColor.ignoresSafeArea())
    }
}


struct SectionView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    var section: Section

    private var cardBackground: Color {
        scrapper.primaryColor.opacity(scrapper.selectedTheme == .night ? 0.10 : 0.06)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                LazyVStack(spacing: 12) {
                    ForEach(scrapper.filteredStories(in: section)) { story in
                        if !story.title.isEmpty {
                            NavigationLink {
                                StoryReaderView(story: story)
                                    .environmentObject(scrapper)
                            } label: {
                                storyCard(story: story)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .background(scrapper.backgroundColor.ignoresSafeArea())
        .refreshable {
            await scrapper.loadSectionsIfNeeded(forceRefresh: true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scrapper.trimmedTitle(section.title))
                .font(.largeTitle.bold())
                .foregroundStyle(scrapper.primaryColor)

            Text("Browse stories in a consistent card layout.")
                .font(.callout)
                .foregroundStyle(scrapper.secondaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func storyCard(story: Story) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(story.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(scrapper.primaryColor)

            Text(story.description)
                .font(.callout)
                .foregroundStyle(scrapper.selectedTheme == .night ? Color.white.opacity(0.88) : scrapper.primaryColor.opacity(0.85))
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
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(scrapper.primaryColor.opacity(0.08), lineWidth: 1)
        )
    }
}
