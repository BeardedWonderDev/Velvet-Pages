//
//  BrowsePageView.swift
//  Sex Stories
//

import SwiftUI

struct BrowsePageView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    let page: BrowsePage
    @State private var scrollToTopToken = UUID()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    Color.clear
                        .frame(height: 1)
                        .id(scrollToTopToken)

                    header

                    LazyVStack(spacing: 12) {
                        ForEach(page.stories) { story in
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
            .onChange(of: page.currentURL) { _, _ in
                scrollToTopToken = UUID()
                withAnimation(.easeInOut) {
                    proxy.scrollTo(scrollToTopToken, anchor: .top)
                }
            }
            .onAppear {
                proxy.scrollTo(scrollToTopToken, anchor: .top)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(page.title.isEmpty ? "Browse" : page.title)
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
                .fill(scrapper.primaryColor.opacity(scrapper.selectedTheme == .night ? 0.10 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(scrapper.primaryColor.opacity(0.08), lineWidth: 1)
        )
    }
}
