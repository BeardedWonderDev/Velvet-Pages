//
//  StoryReaderView.swift
//  Sex Stories
//

import SwiftData
import SwiftUI
import UIKit

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

private struct ReaderCard<Content: View>: View {
    let scrapper: ScrapperViewModel
    let content: Content

    init(scrapper: ScrapperViewModel, @ViewBuilder content: () -> Content) {
        self.scrapper = scrapper
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(20)
        .frame(maxWidth: 760, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(scrapper.primaryColor.opacity(scrapper.selectedTheme == .night ? 0.08 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(scrapper.primaryColor.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct ReaderProgressBar: View {
    let progress: Double
    let scrapper: ScrapperViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(scrapper.primaryColor.opacity(0.12))
                Capsule()
                    .fill(scrapper.accentColor)
                    .frame(width: max(8, geometry.size.width * progress))
            }
        }
        .frame(height: 6)
    }
}

struct StoryReaderView: View {
    @StateObject private var viewModel: StoryReaderViewModel
    @EnvironmentObject var scrapper: ScrapperViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var didConfigureCache = false
    @State private var didRestoreScroll = false
    @State private var showingReaderSettings = false
    @State private var selectedAnchorForBookmark: String?
    @State private var progress: Double = 0

    init(story: Story) {
        _viewModel = StateObject(wrappedValue: StoryReaderViewModel(story: story))
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                readerHeader
                ReaderProgressBar(progress: progress, scrapper: scrapper)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.isLoading && viewModel.blocks.isEmpty {
                            ProgressView("Loading full story...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 96)
                        } else if let error = viewModel.errorMessage {
                            ReaderCard(scrapper: scrapper) {
                                Text(error)
                                    .font(.body)
                                    .foregroundStyle(scrapper.primaryColor)
                                    .multilineTextAlignment(.leading)
                                Text("The cached excerpt is still available below once the parser can recover content.")
                                    .font(.footnote)
                                    .foregroundStyle(scrapper.secondaryColor)
                            }
                        } else {
                            ReaderCard(scrapper: scrapper) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(viewModel.story.title)
                                        .font(.system(size: scrapper.fontSize + 8, weight: .bold, design: .serif))
                                        .foregroundStyle(scrapper.primaryColor)
                                        .fixedSize(horizontal: false, vertical: true)

                                    HStack(spacing: 10) {
                                        if !viewModel.story.author.isEmpty {
                                            Text("By \(viewModel.story.author)")
                                        }
                                        if !viewModel.story.postedDate.isEmpty {
                                            Text(viewModel.story.postedDate)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(scrapper.secondaryColor.opacity(0.80))

                                    if !viewModel.story.themes.isEmpty {
                                        Text(viewModel.story.themes.joined(separator: " • "))
                                            .font(.footnote)
                                            .foregroundStyle(scrapper.secondaryColor.opacity(0.82))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }

                            ReaderCard(scrapper: scrapper) {
                                VStack(alignment: .leading, spacing: 24) {
                                    ForEach(Array(viewModel.blocks.enumerated()), id: \.offset) { _, block in
                                        let anchor = block.stableAnchorID

                                        switch block {
                                        case .heading(let text):
                                            VStack(alignment: .leading, spacing: 0) {
                                                ScrollAnchorMarker(id: anchor)
                                                Text(text)
                                                    .id(anchor)
                                                    .font(.system(size: scrapper.fontSize + 2, weight: .semibold, design: .serif))
                                                    .foregroundStyle(scrapper.primaryColor)
                                                    .padding(.top, 6)
                                                    .fixedSize(horizontal: false, vertical: true)
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
                                                    .padding(.horizontal, 14)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                            .fill(scrapper.accentColor.opacity(0.12))
                                                    )
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }

                                        case .paragraph(let text):
                                            VStack(alignment: .leading, spacing: 0) {
                                                ScrollAnchorMarker(id: anchor)
                                                renderedParagraph(text)
                                                    .id(anchor)
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
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                }
                .coordinateSpace(name: "storyScroll")
            }
            .background(scrapper.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text(viewModel.story.title)
//                        .font(.headline)
//                        .foregroundStyle(scrapper.primaryColor)
//                        .lineLimit(1)
//                }
//
//                ToolbarItem(placement: .topBarLeading) {
//                    Button {
//                        showingReaderSettings.toggle()
//                    } label: {
//                        Image(systemName: "bell.circle")
//                    }
//                }
//
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        if let anchor = selectedAnchorForBookmark {
//                            viewModel.toggleBookmark(anchorID: anchor, title: viewModel.story.title)
//                        }
//                    } label: {
//                        Image(systemName: viewModel.isBookmarked(anchorID: selectedAnchorForBookmark ?? "") ? "bookmark.fill" : "bookmark")
//                    }
//                    .disabled(selectedAnchorForBookmark == nil)
//                }
//            }
            .sheet(isPresented: $showingReaderSettings) {
                ReaderSettingsSheet(viewModel: viewModel, scrapper: scrapper)
                    .presentationDetents([.medium, .large])
            }
            .onPreferenceChange(ScrollAnchorPreferenceKey.self) { positions in
                let topAnchor = positions
                    .filter { $0.value <= 120 }
                    .min(by: { abs($0.value) < abs($1.value) })?
                    .key

                if let topAnchor {
                    selectedAnchorForBookmark = topAnchor
                    viewModel.currentScrollAnchor = topAnchor
                    viewModel.saveScrollAnchor(topAnchor)
                }

                let total = Double(max(viewModel.blocks.count, 1))
                let currentIndex = Double(viewModel.blocks.firstIndex(where: { $0.stableAnchorID == (selectedAnchorForBookmark ?? "") }) ?? 0)
                progress = min(1, (currentIndex + 1) / total)
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

    private var readerHeader: some View {
        HStack(spacing: 10) {
            Text(viewModel.story.title)
                .font(.headline)
                .foregroundStyle(scrapper.primaryColor)
                .lineLimit(1)

            Spacer()

            Button {
                showingReaderSettings.toggle()
            } label: {
                Image(systemName: "bell.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 27, height: 27)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(scrapper.accentColor, scrapper.primaryColor)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(scrapper.backgroundColor.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(scrapper.primaryColor.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var bodyFontName: String {
        switch scrapper.readerFontFamily {
        case .serif: return "Georgia"
        case .sans: return "Helvetica Neue"
        case .rounded: return "Avenir Next Rounded"
        }
    }

    @ViewBuilder
    private func renderedParagraph(_ text: String) -> some View {
        let font = UIFont(name: bodyFontName, size: scrapper.fontSize) ?? UIFont.systemFont(ofSize: scrapper.fontSize)

        if let attributed = viewModel.safeAttributedMarkdown(from: text) {
            Text(attributed)
                .font(.custom(font.fontName, size: scrapper.fontSize))
                .lineSpacing(scrapper.readerLineSpacing)
                .foregroundStyle(scrapper.primaryColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(text)
                .font(.custom(font.fontName, size: scrapper.fontSize))
                .lineSpacing(scrapper.readerLineSpacing)
                .foregroundStyle(scrapper.primaryColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ReaderSettingsSheet: View {
    @ObservedObject var viewModel: StoryReaderViewModel
    @ObservedObject var scrapper: ScrapperViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("Theme") {
                    Picker("Theme", selection: $scrapper.selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.label).tag(theme)
                        }
                    }
                }

                SwiftUI.Section("Font") {
                    Picker("Font Family", selection: $scrapper.readerFontFamily) {
                        ForEach(ReaderFontFamily.allCases) { family in
                            Text(family.label).tag(family)
                        }
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(scrapper.fontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $scrapper.fontSize, in: 14...32, step: 1)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Line Spacing")
                            Spacer()
                            Text("\(Int(scrapper.readerLineSpacing))")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $scrapper.readerLineSpacing, in: 0...14, step: 1)
                    }
                }

                SwiftUI.Section("Bookmarks") {
                    if viewModel.currentBookmarks().isEmpty {
                        Text("No bookmarks yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.currentBookmarks()) { bookmark in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bookmark.title)
                                Text(bookmark.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reader Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
