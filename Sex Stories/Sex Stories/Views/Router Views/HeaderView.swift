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
                            scrapper.surfaceColor,
                            scrapper.elevatedSurfaceColor.opacity(scrapper.selectedTheme == .night ? 0.92 : 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(scrapper.borderColor, lineWidth: 1)
                )
                .shadow(color: .black.opacity(scrapper.softShadowOpacity), radius: 10, x: 0, y: 4)
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
                        .fill(scrapper.controlFillColor)
                )
        }
        .buttonStyle(.plain)
    }
}
-    }
-
-    private func controlButton(systemName: String, action: @escaping () -> Void) -> some View {
-        Button(action: action) {
-            Image(systemName: systemName)
-                .font(.system(size: 16, weight: .semibold))
-                .foregroundStyle(scrapper.primaryColor)
-                .frame(width: 34, height: 34)
-                .background(
-                    RoundedRectangle(cornerRadius: 11, style: .continuous)
-                        .fill(scrapper.primaryColor.opacity(0.08))
-                )
-        }
-        .buttonStyle(.plain)
-    }
-}
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
