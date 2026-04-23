//
//  Home.swift
//  ResponsiveUI
//
//  Created by BoiseITGuru on 3/29/23.
//

import SwiftUI
import Charts

struct RouterView: View {
    @ObservedObject var props: AppProperties
    @EnvironmentObject var scrapper: ScrapperViewModel
    @SceneStorage("showSideBar") var showSideBar: Bool = false
    @SceneStorage("showSettings") var showSettings: Bool = false
    @SceneStorage("selectedSectionIndex") var selectedSectionIndex: Int = -1
    @SceneStorage("showFilters") var showFilters: Bool = false

    private var selectedSection: Section? {
        guard scrapper.sections.indices.contains(selectedSectionIndex) else { return scrapper.sections.first }
        return scrapper.sections[selectedSectionIndex]
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                if props.isiPad && props.isLandscape {
                    SidebarView()
                }

                ZStack(alignment: .top) {
                    if showSettings {
                        SettingsView()
                    } else if selectedSectionIndex >= 0 {
                        ContentView(section: selectedSection)
                    } else if scrapper.activeBrowsePage != nil {
                        ContentView(section: nil)
                    } else {
                        LibraryView()
                    }
                    
                    HeaderView()
                        .padding(.horizontal, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                scrapper.backgroundColor.ignoresSafeArea()
            }
            .offset(x: showSideBar ? SidebarView.sidebarWidth : 0)
            .overlay(alignment: .leading) {
                SidebarView()
                    .offset(x: showSideBar ? 0 : -SidebarView.sidebarWidth)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        scrapper.primaryColor
                            .opacity(showSideBar ? (scrapper.selectedTheme == .night ? 0.50 : 0.28) : 0)
                            .offset(x: showSideBar ? SidebarView.sidebarWidth : 0)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    showSideBar.toggle()
                                }
                            }
                    }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheetView()
                    .environmentObject(scrapper)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .environmentObject(props)
            .environmentObject(scrapper)
            .onChange(of: props.isLandscape) { _, _ in
                showSideBar = false
                showFilters = false
            }
            .onChange(of: scrapper.sections.count) { _, newValue in
                if selectedSectionIndex >= newValue {
                    selectedSectionIndex = newValue > 0 ? newValue - 1 : -1
                }
            }
        }
    }
}
