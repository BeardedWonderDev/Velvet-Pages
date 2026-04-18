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
    @SceneStorage("selectedSectionIndex") var selectedSectionIndex: Int = 0

    private var selectedSection: Section? {
        guard scrapper.sections.indices.contains(selectedSectionIndex) else { return scrapper.sections.first }
        return scrapper.sections[selectedSectionIndex]
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                if (props.isiPad && props.isLandscape) {
                    ViewThatFits {
                        SidebarView()
                        ScrollView(.vertical, showsIndicators: false) {
                            SidebarView()
                                .scrollContentBackground(.hidden)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }

                VStack(alignment: .leading) {
                    HeaderView()
                        .padding(.horizontal, 10)

                    if showSettings {
                        SettingsView()
                    } else {
                        ContentView(section: selectedSection)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                scrapper.backgroundColor
                    .ignoresSafeArea()
            }
            .offset(x: showSideBar ? 100 : 0)
            .overlay(alignment: .leading) {
                ViewThatFits {
                    SidebarView()
                    ScrollView(.vertical, showsIndicators: false) {
                        SidebarView()
                            .scrollContentBackground(.hidden)
                    }
                    .scrollContentBackground(.hidden)
                }
                .offset(x: showSideBar ? 0 : -100)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    Color.black
                        .opacity(showSideBar ? 0.5 : 0)
                        .offset(x: showSideBar ? 100 : 0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showSideBar.toggle()
                            }
                        }
                }
            }
            .environmentObject(props)
            .environmentObject(scrapper)
            .onChange(of: props.isLandscape) { _, _ in
                showSideBar = false
            }
            .onChange(of: scrapper.sections.count) { _, newValue in
                if selectedSectionIndex >= newValue {
                    selectedSectionIndex = max(0, newValue - 1)
                }
            }
        }
    }
}
