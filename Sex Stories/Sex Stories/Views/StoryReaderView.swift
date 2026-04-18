//
//  StoryReaderView.swift
//  Sex Stories
//

import SwiftData
import SwiftUI

private struct ScrollAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct ScrollAnchorMarker: View {
    let id: String

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ScrollAnchorPreferenceKey.self, value: [id: geometry.frame(in: .named("storyScroll")).minY])
        }
        .frame(height: 0)
    }
}

struct StoryReaderView: View {
    @StateObject private var viewModel: StoryReaderViewModel
    @EnvironmentObject var scrapper: ScrapperViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var didConfigureCache = false
    @State private var didRestoreScroll = false
    
    init(story: Story) {
        _viewModel = StateObject(wrappedValue: StoryReaderViewModel(story: story))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if viewModel.isLoading && viewModel.blocks.isEmpty {
                        ProgressView("Loading full story...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 80)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(viewModel.story.title)
                                .font(.system(size: scrapper.fontSize + 6, weight: .bold, design: .serif))
                                .foregroundStyle(scrapper.primaryColor)
                            
                            HStack {
                                if !viewModel.story.author.isEmpty {
                                    Text("By \(viewModel.story.author)")
                                }
                                if !viewModel.story.postedDate.isEmpty {
                                    Text(viewModel.story.postedDate)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(scrapper.secondaryColor.opacity(0.72))
                            
                            if !viewModel.story.themes.isEmpty {
                                Text(viewModel.story.themes.joined(separator: " • "))
                                    .font(.footnote)
                                    .foregroundStyle(scrapper.secondaryColor.opacity(0.72))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(Array(viewModel.blocks.enumerated()), id: \.offset) { index, block in
                                let anchor = block.stableAnchorID
                                
                                switch block {
                                case .heading(let text):
                                    VStack(alignment: .leading, spacing: 0) {
                                        ScrollAnchorMarker(id: anchor)
                                        Text(text)
                                            .id(anchor)
                                            .font(.system(size: scrapper.fontSize + 2, weight: .bold, design: .serif))
                                            .foregroundStyle(scrapper.primaryColor)
                                            .padding(.top, 8)
                                    }
                                    
                                case .chapterTitle(let text):
                                    VStack(alignment: .leading, spacing: 0) {
                                        ScrollAnchorMarker(id: anchor)
                                        Text(text)
                                            .id(anchor)
                                            .font(.system(size: scrapper.fontSize + 6, weight: .bold, design: .serif))
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(scrapper.primaryColor)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 20)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(scrapper.accentColor.opacity(0.12))
                                            )
                                    }
                                    
                                case .paragraph(let text):
                                    VStack(alignment: .leading, spacing: 0) {
                                        ScrollAnchorMarker(id: anchor)
                                        Text(try! AttributedString(markdown: text))
                                            .id(anchor)
                                            .font(.system(size: scrapper.fontSize, weight: .regular, design: .serif))
                                            .lineSpacing(1.4)
                                            .foregroundStyle(scrapper.primaryColor)
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                case .separator:
                                    VStack(alignment: .leading, spacing: 0) {
                                        ScrollAnchorMarker(id: anchor)
                                        Divider()
                                            .id(anchor)
                                            .padding(.vertical, 12)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .coordinateSpace(name: "storyScroll")
            .background(scrapper.backgroundColor.ignoresSafeArea())
            .navigationTitle("Reader")
            .navigationBarTitleDisplayMode(.inline)
            .onPreferenceChange(ScrollAnchorPreferenceKey.self) { positions in
                let topAnchor = positions
                    .filter { $0.value <= 120 }
                    .min(by: { abs($0.value) < abs($1.value) })?
                    .key
                
                if let topAnchor {
                    viewModel.currentScrollAnchor = topAnchor
                    viewModel.saveScrollAnchor(topAnchor)
                }
            }
            .task {
                if !didConfigureCache {
                    viewModel.configureCacheStore(modelContext)
                    didConfigureCache = true
                }
                await viewModel.loadStoryIfNeeded()
                
                if !didRestoreScroll, let anchor = viewModel.resolvedScrollAnchor(from: viewModel.restoredScrollAnchor) {
                    didRestoreScroll = true
                    DispatchQueue.main.async {
                        proxy.scrollTo(anchor, anchor: .top)
                    }
                }
            }
            .onDisappear {
                let anchor = viewModel.currentScrollAnchor ?? viewModel.restoredScrollAnchor
                viewModel.saveScrollAnchor(anchor)
                if !viewModel.blocks.isEmpty {
                    let total = Double(max(viewModel.blocks.count, 1))
                    let currentIndex = Double(viewModel.blocks.firstIndex(where: { $0.stableAnchorID == anchor }) ?? 0)
                    viewModel.saveReadingProgress(min(1, (currentIndex + 1) / total))
                }
            }
        }
    }
}
