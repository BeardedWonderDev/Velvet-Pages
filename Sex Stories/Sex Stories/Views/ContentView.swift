//
//  ContentView.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    let section: Section?

    init(section: Section? = nil) {
        self.section = section
    }

    var body: some View {
        Group {
            if scrapper.isConnected {
                if scrapper.isLoading && scrapper.sections.isEmpty {
                    ProgressView("Loading")
                } else if let loadError = scrapper.loadError {
                    VStack(spacing: 12) {
                        Text(loadError)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(scrapper.primaryColor)
                        Button("Try Again") {
                            Task {
                                await scrapper.loadSectionsIfNeeded(forceRefresh: true)
                            }
                        }
                    }
                    .padding()
                } else if let section {
                    SectionView(section: section)
                        .environmentObject(scrapper)
                } else if let firstSection = scrapper.sections.first {
                    SectionView(section: firstSection)
                        .environmentObject(scrapper)
                } else {
                    Text("Loading")
                }
            } else {
                Text("No Network Available")
                    .foregroundStyle(scrapper.primaryColor)
            }
        }
    }
}


struct SectionView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    var section: Section

    private var cardBackground: Color {
        switch scrapper.selectedTheme {
        case .night:
            return Color(red: 0.14, green: 0.15, blue: 0.22)
        case .sepia:
            return Color(red: 0.98, green: 0.93, blue: 0.83)
        case .paper:
            return Color(red: 0.99, green: 0.98, blue: 0.96)
        case .light:
            return Color.white
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(section.stories) { story in
                    if !story.title.isEmpty {
                        NavigationLink {
                            StoryReaderView(story: story)
                                .environmentObject(scrapper)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(story.title)
                                    .font(.title2)
                                    .foregroundStyle(scrapper.primaryColor)
                                
                                Text(story.description)
                                    .font(.callout)
                                    .foregroundStyle(scrapper.selectedTheme == .night ? Color.white.opacity(0.88) : scrapper.primaryColor.opacity(0.85))
                                    .padding(.bottom, 8)

                                Text("Themes:")
                                    .font(.headline)
                                    .foregroundStyle(scrapper.primaryColor)
                                Text(story.themes.joined(separator: ", "))
                                    .font(.footnote)
                                    .foregroundStyle(scrapper.secondaryColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(cardBackground)
                                    .shadow(color: .black.opacity(scrapper.selectedTheme == .night ? 0.35 : 0.12), radius: 10, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(scrapper.primaryColor.opacity(scrapper.selectedTheme == .night ? 0.16 : 0.08), lineWidth: 1)
                            )
                            .padding(.horizontal, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .background(scrapper.backgroundColor.ignoresSafeArea())
        .refreshable {
            await scrapper.loadSectionsIfNeeded(forceRefresh: true)
        }
    }
}
