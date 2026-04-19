//
//  SidebarView.swift
//  Consensual Connections
//
//  Created by BoiseITGuru on 4/11/23.
//

import SwiftUI

struct SidebarView: View {
    static let sidebarWidth: CGFloat = 250

    @Namespace var animation
    @SceneStorage("selectedSectionIndex") var selectedSectionIndex: Int = 0
    @SceneStorage("showSideBar") var showSideBar: Bool = false
    @SceneStorage("showSettings") var showSettings: Bool = false
    @SceneStorage("showGenresMenu") var showGenresMenu: Bool = false
    @SceneStorage("showCategoriesMenu") var showCategoriesMenu: Bool = false
    @SceneStorage("selectedBrowseTitle") var selectedBrowseTitle: String = ""
    @SceneStorage("selectedBrowseURL") var selectedBrowseURL: String = ""
    @EnvironmentObject var scrapper: ScrapperViewModel

    private var sectionItems: [Section] {
        scrapper.sections
    }

    private var genreItems: [MenuItem] {
        scrapper.menuSections.first(where: { $0.title == "Genres" })?.items ?? []
    }

    private var categoryItems: [MenuItem] {
        scrapper.allKnownCategories.map { category in
            MenuItem(name: category.name, url: "", count: nil)
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(scrapper.accentColor.opacity(0.14))
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(scrapper.accentColor)
                    }
                    .frame(width: 28, height: 28)

                    Text("SexStories.com")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(scrapper.primaryColor)

                    Spacer(minLength: 0)
                }
                .padding(.bottom, 10)

                sidebarItem(
                    title: "Library",
                    systemImage: "books.vertical",
                    isSelected: !showSettings && selectedSectionIndex < 0,
                    action: {
                        withAnimation(.easeInOut) {
                            showSettings = false
                            selectedSectionIndex = -1
                            scrapper.activeBrowsePage = nil
                            scrapper.storyFilterState = StoryFilterState()
                            showSideBar.toggle()
                        }
                    }
                )
                
                collapsibleMenuSection(
                    title: "Genres",
                    systemImage: "tag.fill",
                    isExpanded: $showGenresMenu,
                    items: genreItems,
                    onSelect: { item in
                        Task {
                            await scrapper.loadBrowsePage(title: item.name, urlString: item.url)
                        }
                        showSettings = false
                        showGenresMenu = false
                        selectedSectionIndex = -1
                        showSideBar = false
                    }
                )

//                collapsibleMenuSection(
//                    title: "Categories",
//                    systemImage: "square.grid.2x2.fill",
//                    isExpanded: $showCategoriesMenu,
//                    items: categoryItems,
//                    onSelect: { item in
//                        Task { await scrapper.loadBrowsePage(title: item.name, urlString: item.url) }
//                        showSettings = false
//                        showCategoriesMenu.toggle()
//                        selectedSectionIndex = -1
//                        showSideBar.toggle()
//                    }
//                )

                ForEach(Array(sectionItems.enumerated()), id: \.offset) { index, section in
                    sidebarItem(
                        title: scrapper.trimmedTitle(section.title),
                        systemImage: "book.closed",
                        isSelected: !showSettings && selectedSectionIndex == index,
                        action: {
                            withAnimation(.easeInOut) {
                                showSettings = false
                                selectedSectionIndex = index
                                showSideBar.toggle()
                            }
                        }
                    )
                }

                Spacer(minLength: 8)

                sidebarItem(
                    title: "Settings",
                    systemImage: "gearshape",
                    isSelected: showSettings,
                    action: {
                        withAnimation(.easeInOut) {
                            showSettings = true
                            showSideBar.toggle()
                        }
                    }
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(scrapper.backgroundColor.opacity(0.92).ignoresSafeArea())
        .frame(width: Self.sidebarWidth)
        .onChange(of: scrapper.sections.count) { _, newValue in
            if selectedSectionIndex >= newValue {
                selectedSectionIndex = max(0, newValue - 1)
            }
        }
    }

    @ViewBuilder
    private func sidebarItem(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? scrapper.accentColor.opacity(0.14) : scrapper.primaryColor.opacity(0.06))
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? scrapper.accentColor : scrapper.secondaryColor)
            }
            .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? scrapper.primaryColor : scrapper.secondaryColor)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                scrapper.primaryColor.opacity(0.18),
                                scrapper.primaryColor.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(scrapper.primaryColor.opacity(0.10), lineWidth: 1)
                    )
                    .matchedGeometryEffect(id: "TAB", in: animation)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture(perform: action)
    }

    @ViewBuilder
    private func collapsibleMenuSection(title: String, systemImage: String, isExpanded: Binding<Bool>, items: [MenuItem], onSelect: @escaping (MenuItem) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(scrapper.primaryColor.opacity(0.06))
                        Image(systemName: systemImage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(scrapper.secondaryColor)
                    }
                    .frame(width: 28, height: 28)

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(scrapper.primaryColor)

                    Spacer(minLength: 0)

                    Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(scrapper.secondaryColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            sidebarSubItem(title: item.name, count: item.count)
                                .padding(.leading, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func sidebarSubItem(title: String, count: String?) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(scrapper.secondaryColor.opacity(0.6))
                .frame(width: 5, height: 5)

            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(scrapper.secondaryColor)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let count, !count.isEmpty {
                Text(count)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(scrapper.secondaryColor.opacity(0.75))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
