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
    @SceneStorage("selectedPage") var selectedPage: AppPages = .home

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                if (props.isiPad && props.isLandscape) {
                    ViewThatFits {
                        SidebarView()
                        ScrollView(.vertical, showsIndicators: false) {
                            SidebarView()
                        }
                    }
                }

                VStack(alignment: .leading) {
                    HeaderView()
                        .padding(.horizontal, 10)

                    switch selectedPage {
                    case .home:
                        ContentView()
                    case .profile:
                        Text("Profile View")
                    case .partners:
                        Text("Partners View")
                    case .settings:
                        SettingsView()
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
                    }
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
        }
    }
}
