//
//  HeaderView.swift
//  Consensual Connections
//
//  Created by BoiseITGuru on 4/11/23.
//

import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var props: AppProperties
    @EnvironmentObject var scrapper: ScrapperViewModel

    @SceneStorage("selectedSectionIndex") var selectedSectionIndex: Int = 0
    @SceneStorage("showSettings") var showSettings: Bool = false
    @SceneStorage("showSideBar") var showSideBar: Bool = false
    @SceneStorage("showFilters") var showFilters: Bool = false

    private var headerTitle: String {
        if showSettings { return "Settings" }
        if let browseTitle = scrapper.activeBrowsePage?.title, !browseTitle.isEmpty {
            return browseTitle
        }
        if selectedSectionIndex < 0 { return "Library" }
        guard scrapper.sections.indices.contains(selectedSectionIndex) else { return "Stories" }
        return scrapper.trimmedTitle(scrapper.sections[selectedSectionIndex].title)
    }

    private var headerSubtitle: String {
        if showSettings { return "Preferences" }
        if scrapper.activeBrowsePage != nil { return "Browse" }
        if selectedSectionIndex < 0 { return "Pick up, save, or browse stories." }
        return "Stories"
    }

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 10) {
                if !props.isiPad || (props.isiPad && !props.isLandscape) {
                    controlButton(systemName: "line.3.horizontal") {
                        withAnimation(.easeInOut) {
                            showSideBar.toggle()
                        }
                    }
                }

                VStack(alignment: .center, spacing: 2) {
                    Text(headerTitle)
                        .font(.title3.bold())
                        .foregroundStyle(scrapper.primaryColor)
                    Text(headerSubtitle)
                        .font(.caption)
                        .foregroundStyle(scrapper.secondaryColor)
                }
                .frame(maxWidth: .infinity)

                controlButton(systemName: "line.3.horizontal.decrease") {
                    showFilters.toggle()
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .glassEffect(.clear)
        }
    }

    private func controlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(scrapper.primaryColor)
                .frame(width: 38, height: 38)
                
        }
        .glassEffect(.clear.interactive())
        .contentShape(Rectangle())
    }
}
