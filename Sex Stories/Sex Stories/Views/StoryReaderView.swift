//
//  StoryReaderView.swift
//  Sex Stories
//

import SwiftData
import SwiftUI

struct StoryReaderView: View {
    @StateObject private var viewModel: StoryReaderViewModel
    @EnvironmentObject var scrapper: ScrapperViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var didConfigureCache = false
    
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
                                switch block {
                                case .heading(let text):
                                    Text(text)
                                        .id("block-\(index)")
                                        .font(.system(size: scrapper.fontSize + 2, weight: .bold, design: .serif))
                                        .foregroundStyle(scrapper.primaryColor)
                                        .padding(.top, 8)
                                    
                                case .chapterTitle(let text):
                                    Text(text)
                                        .id("block-\(index)")
                                        .font(.system(size: scrapper.fontSize + 6, weight: .bold, design: .serif))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(scrapper.primaryColor)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(scrapper.accentColor.opacity(0.12))
                                        )
                                    
                                case .paragraph(let text):
                                    Text(try! AttributedString(markdown: text))
                                        .id("block-\(index)")
                                        .font(.system(size: scrapper.fontSize, weight: .regular, design: .serif))
                                        .lineSpacing(1.4)
                                        .foregroundStyle(scrapper.primaryColor)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                case .separator:
                                    Divider()
                                        .id("block-\(index)")
                                        .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(scrapper.backgroundColor.ignoresSafeArea())
            .navigationTitle("Reader")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if !didConfigureCache {
                    viewModel.configureCacheStore(modelContext)
                    didConfigureCache = true
                }
                await viewModel.loadStoryIfNeeded()
                if let anchor = viewModel.restoredScrollAnchor {
                    DispatchQueue.main.async {
                        proxy.scrollTo(anchor, anchor: .top)
                    }
                }
            }
            .onDisappear {
                viewModel.saveScrollAnchor(viewModel.restoredScrollAnchor)
            }
        }
    }
}
