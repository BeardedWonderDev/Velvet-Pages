//
//  FilterSheetView.swift
//  Sex Stories
//

import SwiftUI

struct FilterSheetView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel

    private let categoryColumns = [GridItem(.adaptive(minimum: 92), spacing: 8, alignment: .leading)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                themedCard(title: "Story Filters") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Favorites only", isOn: $scrapper.storyFilterState.showOnlyFavorites)
                            .tint(scrapper.accentColor)
                            .toggleStyle(.switch)
                        Toggle("Continue reading only", isOn: $scrapper.storyFilterState.showOnlyContinueReading)
                            .tint(scrapper.accentColor)
                            .toggleStyle(.switch)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search")
                                .font(.subheadline.weight(.semibold))
                            TextField("Title, author, description", text: $scrapper.storyFilterState.searchText)
                                .textFieldStyle(.roundedBorder)
                                .tint(scrapper.accentColor)
                        }

                        if !scrapper.allKnownCategories.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Categories")
                                    .font(.subheadline.weight(.semibold))

                                LazyVGrid(columns: categoryColumns, alignment: .leading, spacing: 8) {
                                    ForEach(scrapper.allKnownCategories) { category in
                                        CategoryChip(
                                            title: category.name,
                                            isSelected: scrapper.storyFilterState.selectedCategories.contains(category.name),
                                            accentColor: scrapper.accentColor,
                                            backgroundColor: scrapper.primaryColor.opacity(scrapper.selectedTheme == .night ? 0.16 : 0.10)
                                        ) {
                                            toggle(category.name)
                                        }
                                    }
                                }
                            }
                        }

                        HStack {
                            Button("Clear Filters") {
                                scrapper.storyFilterState = StoryFilterState()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(scrapper.accentColor)

                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .background(scrapper.backgroundColor.ignoresSafeArea())
        .foregroundStyle(scrapper.primaryColor)
    }

    private func themedCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(scrapper.primaryColor)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(scrapper.primaryColor.opacity(scrapper.selectedTheme == .night ? 0.08 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(scrapper.primaryColor.opacity(0.12), lineWidth: 1)
        )
    }

    private func toggle(_ category: String) {
        if scrapper.storyFilterState.selectedCategories.contains(category) {
            scrapper.storyFilterState.selectedCategories.remove(category)
        } else {
            scrapper.storyFilterState.selectedCategories.insert(category)
        }
    }
}

struct CategoryChip: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(isSelected ? Color.white : accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? accentColor : backgroundColor)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(accentColor.opacity(isSelected ? 0 : 0.18), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
