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
            VStack(alignment: .leading, spacing: 18) {
                if viewModel.isLoading && viewModel.blocks.isEmpty {
                    ProgressView("Loading story")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.story.title)
                            .font(.title.bold())

                        HStack {
                            if !viewModel.story.author.isEmpty {
                                Text("By \(viewModel.story.author)")
                            }
                            if !viewModel.story.postedDate.isEmpty {
                                Text(viewModel.story.postedDate)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if !viewModel.story.themes.isEmpty {
                            Text(viewModel.story.themes.joined(separator: " • "))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    readerControls

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(viewModel.blocks.enumerated()), id: \.offset) { _, block in
                            switch block {
                            case .heading(let text):
                                Text(text)
                                    .font(.title3.bold())
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            case .paragraph(let text):
                                Text(text)
                                    .font(viewModel.readerFont)
                                    .lineSpacing(viewModel.lineSpacing)
                                    .foregroundStyle(viewModel.readerTextColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            case .separator:
                                Divider()
                                    .opacity(0.5)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(viewModel.readerBackground.ignoresSafeArea())
        .navigationTitle("Reader")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadStoryIfNeeded()
        }
    }

    private var readerControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Background", selection: $viewModel.readerTheme) {
                ForEach(StoryReaderTheme.allCases, id: \.self) { theme in
                    Text(theme.rawValue.capitalized).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading) {
                HStack {
                    Text("Text Size")
                    Spacer()
                    Text("\(Int(viewModel.fontSize))")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.fontSize, in: 14...30, step: 1)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Line Spacing")
                    Spacer()
                    Text(String(format: "%.1f", viewModel.lineSpacing))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.lineSpacing, in: 1.0...2.2, step: 0.1)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
