//
//  LibraryView.swift
//  Sex Stories
//

import SwiftData
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    @SceneStorage("selectedSectionIndex") var selectedSectionIndex: Int = -1
    @SceneStorage("showSettings") var showSettings: Bool = false
    @Query(sort: [SortDescriptor(\CachedStoryRecord.lastUpdated, order: .reverse)]) private var cachedStories: [CachedStoryRecord]

    private var continueReadingStories: [CachedStorySnapshot] {
        cachedStories
            .compactMap { $0.snapshot }
            .sorted {
                if $0.lastUpdated == $1.lastUpdated {
                    return $0.lastReadProgress > $1.lastReadProgress
                }
                return $0.lastUpdated > $1.lastUpdated
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !continueReadingStories.isEmpty {
                    sectionBlock(title: "Continue Reading", subtitle: "Stories sorted by most recent activity.") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(continueReadingStories.prefix(6), id: \.storyID) { story in
                                    if let resolvedStory = resolveStory(for: story) {
                                        NavigationLink {
                                            StoryReaderView(story: resolvedStory)
                                                .environmentObject(scrapper)
                                        } label: {
                                            continueReadingCard(snapshot: story)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        continueReadingCard(snapshot: story)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if !scrapper.sections.isEmpty {
                    sectionBlock(title: "Browse", subtitle: "Explore everything available in the library.") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                            ForEach(Array(scrapper.sections.enumerated()), id: \.offset) { index, section in
                                Button {
                                    showSettings = false
                                    selectedSectionIndex = index
                                } label: {
                                    browseCard(section: section)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(scrapper.backgroundColor.ignoresSafeArea())
    }

    private func resolveStory(for snapshot: CachedStorySnapshot) -> Story? {
        for section in scrapper.sections {
            if let story = section.stories.first(where: { $0.id == snapshot.storyID || $0.url == snapshot.storyURL }) {
                return story
            }
        }
        return nil
    }

    private func continueReadingCard(snapshot: CachedStorySnapshot) -> some View {
        let progress = max(0, min(1, snapshot.lastReadProgress))
        return VStack(alignment: .leading, spacing: 10) {
            Text(snapshot.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(scrapper.primaryColor)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(snapshot.author.isEmpty ? snapshot.storyDescription : "By \(snapshot.author)")
                .font(.caption)
                .foregroundStyle(scrapper.secondaryColor)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(scrapper.primaryColor.opacity(0.10))
                        Capsule()
                            .fill(scrapper.accentColor)
                            .frame(width: proxy.size.width * progress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(Int(progress * 100))% read")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(scrapper.secondaryColor)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(scrapper.accentColor)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .padding(14)
        .frame(width: 240, height: 150, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(scrapper.backgroundColor.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(scrapper.primaryColor.opacity(0.08), lineWidth: 1)
        )
    }

    private func sectionBlock<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
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
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(scrapper.primaryColor.opacity(scrapper.selectedTheme == .night ? 0.06 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(scrapper.primaryColor.opacity(0.08), lineWidth: 1)
        )
    }

    private func pill(label: String) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(scrapper.primaryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(scrapper.primaryColor.opacity(0.10))
            )
    }

    private func browseCard(section: Section) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "books.vertical")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(scrapper.accentColor)

            Text(scrapper.trimmedTitle(section.title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(scrapper.primaryColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("Open section")
                .font(.caption)
                .foregroundStyle(scrapper.secondaryColor)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(scrapper.backgroundColor.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(scrapper.primaryColor.opacity(0.08), lineWidth: 1)
        )
    }
}

