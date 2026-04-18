//
//  SidebarView.swift
//  Consensual Connections
//
//  Created by BoiseITGuru on 4/11/23.
//

import SwiftUI

struct SidebarView: View {
    @Namespace var animation
    @SceneStorage("selectedSectionIndex") var selectedSectionIndex: Int = 0
    @SceneStorage("showSettings") var showSettings: Bool = false
    @EnvironmentObject var scrapper: ScrapperViewModel

    private var sectionItems: [Section] {
        scrapper.sections
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 55, height: 55)
                .symbolRenderingMode(.palette)
                .foregroundStyle(scrapper.accentColor, scrapper.primaryColor)
                .padding(.bottom, 20)

            ForEach(Array(sectionItems.enumerated()), id: \.offset) { index, section in
                sidebarItem(
                    title: scrapper.trimmedTitle(section.title),
                    systemImage: "book.closed",
                    isSelected: !showSettings && selectedSectionIndex == index,
                    action: {
                        withAnimation(.easeInOut) {
                            showSettings = false
                            selectedSectionIndex = index
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
                    }
                }
            )
        }
        .padding(.vertical, 15)
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(width: 100)
        .background {
            scrapper.backgroundColor.opacity(0.92)
                .ignoresSafeArea()
        }
        .scrollContentBackground(.hidden)
        .background(scrapper.backgroundColor.opacity(0.92))
        .onChange(of: scrapper.sections.count) { _, newValue in
            if selectedSectionIndex >= newValue {
                selectedSectionIndex = max(0, newValue - 1)
            }
        }
    }

    @ViewBuilder
    private func sidebarItem(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 33, height: 33)
                .symbolRenderingMode(.palette)
                .foregroundStyle(scrapper.accentColor, scrapper.primaryColor)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .foregroundColor(isSelected ? scrapper.accentColor : scrapper.secondaryColor)
        .padding(.vertical, 13)
        .frame(width: 65)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(scrapper.primaryColor.opacity(0.18))
                    .matchedGeometryEffect(id: "TAB", in: animation)
            }
        }
        .onTapGesture(perform: action)
    }
}
