//
//  ContentView.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel

    var body: some View {
        Group {
            if scrapper.isConnected {
                if scrapper.isLoading && scrapper.sections.isEmpty {
                    ProgressView("Loading")
                } else if let loadError = scrapper.loadError {
                    VStack(spacing: 12) {
                        Text(loadError)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await scrapper.loadSectionsIfNeeded(forceRefresh: true)
                            }
                        }
                    }
                    .padding()
                } else {
                    TabView {
                        if scrapper.sections.isEmpty {
                            Text("Loading")
                        } else {
                            ForEach(scrapper.sections, id: \.title) { section in
                                SectionView(section: section)
                                    .environmentObject(scrapper)
                                    .tabItem {
                                        Text(scrapper.trimmedTitle(section.title))
                                    }
                            }
                        }
                    }
                    .tabBarMinimizeBehavior(.onScrollDown)
                }
            } else {
                Text("No Network Available")
            }
        }
    }
}

struct SectionView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    var section: Section

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(section.stories) { story in
                    if !story.title.isEmpty {
                        NavigationLink {
                            StoryReaderView(story: story)
                                .environmentObject(scrapper)
                        } label: {
                            GroupBox(label: (
                                Text(story.title)
                                    .font(.title2)
                            ), content: {
                                VStack(alignment: .leading) {
                                    Text(story.description)
                                        .font(.callout)
                                        .padding(.bottom, 20)

                                    Text("Themes:")
                                        .font(.headline)
                                    Text(story.themes.joined(separator: ", "))
                                        .font(.footnote)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            })
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .refreshable {
            await scrapper.loadSectionsIfNeeded(forceRefresh: true)
        }
    }
}
