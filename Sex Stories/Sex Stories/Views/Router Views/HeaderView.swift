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
        if selectedSectionIndex < 0 { return "Library" }
        guard scrapper.sections.indices.contains(selectedSectionIndex) else { return "Stories" }
        return scrapper.trimmedTitle(scrapper.sections[selectedSectionIndex].title)
    }

    private var headerSubtitle: String {
        if showSettings { return "Preferences" }
        if selectedSectionIndex < 0 { return "Pick up, save, or browse stories." }
        return "Stories"
    }

    var body: some View {
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
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            scrapper.backgroundColor.opacity(0.96),
                            scrapper.backgroundColor.opacity(0.84)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(scrapper.primaryColor.opacity(0.08), lineWidth: 1)
                )
        }
    }

    private func controlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(scrapper.primaryColor)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(scrapper.primaryColor.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }
}
