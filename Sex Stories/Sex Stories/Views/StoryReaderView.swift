//
//  StoryReaderView.swift
//  Sex Stories
//

import SwiftUI

struct StoryReaderView: View {
    @StateObject private var viewModel: StoryReaderViewModel
    @EnvironmentObject var scrapper: ScrapperViewModel
    
    init(story: Story) {
        _viewModel = StateObject(wrappedValue: StoryReaderViewModel(story: story))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if viewModel.isLoading && viewModel.blocks.isEmpty {
                    ProgressView("Loading full story...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 80)
                }
                else if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).multilineTextAlignment(.center)
                }
                else {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.story.title)
                            .font(.title.bold())
                            .foregroundStyle(viewModel.readerTextColor)
                        
                        HStack {
                            if !viewModel.story.author.isEmpty {
                                Text("By \(viewModel.story.author)")
                            }
                            if !viewModel.story.postedDate.isEmpty {
                                Text(viewModel.story.postedDate)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(viewModel.readerTextColor.opacity(0.72))
                        
                        if !viewModel.story.themes.isEmpty {
                            Text(viewModel.story.themes.joined(separator: " • "))
                                .font(.footnote)
                                .foregroundStyle(viewModel.readerTextColor.opacity(0.72))
                        }
                    }
                    
                    readerControls
                    
                    // Story Content
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(viewModel.blocks.enumerated()), id: \.offset) { _, block in
                            switch block {
                            case .heading(let text):
                                Text(text)
                                    .font(.title2.bold())
                                    .foregroundStyle(viewModel.readerTextColor)
                                    .padding(.top, 8)
                                
                            case .chapterTitle(let text):
                                Text(text)
                                    .font(.title.bold())
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(viewModel.readerTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(viewModel.readerAccentColor.opacity(0.12))
                                    )
                                
                            case .paragraph(let text):
                                Text(try! AttributedString(markdown: text))
                                    .font(viewModel.readerFont)
                                    .lineSpacing(viewModel.lineSpacing)
                                    .foregroundStyle(viewModel.readerTextColor)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                            case .separator:
                                Divider().padding(.vertical, 12)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(viewModel.readerBackground.ignoresSafeArea())
        .navigationTitle("Reader")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadStoryIfNeeded()
        }
    }
    
    private var readerControls: some View {
        VStack(spacing: 18) {
            Picker("Background", selection: $viewModel.readerTheme) {
                ForEach(StoryReaderTheme.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            
            VStack {
                HStack {
                    Text("Text Size")
                    Spacer()
                    Text("\(Int(viewModel.fontSize)) pt")
                }
                Slider(value: $viewModel.fontSize, in: 14...32, step: 1)
            }
            
            VStack {
                HStack {
                    Text("Line Spacing")
                    Spacer()
                    Text(String(format: "%.1f", viewModel.lineSpacing))
                }
                Slider(value: $viewModel.lineSpacing, in: 1.0...2.6, step: 0.1)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func themeLabel(_ theme: AppTheme) -> String {
        switch theme {
        case .classicReadability: return "Classic"
        case .modernMinimalist: return "Minimal"
        case .nightMode: return "Night"
        case .natureInspired: return "Nature"
        }
    }
}
