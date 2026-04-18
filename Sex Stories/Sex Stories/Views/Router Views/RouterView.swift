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
        HStack(spacing: 0) {
            // Showing Only For IPad
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
                case .account:
                    Text("Account View")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            Color.black
                .opacity(0.01)
                .ignoresSafeArea()
        }
        .offset(x: showSideBar ? 100 : 0)
        .overlay(alignment: .leading) {
            // Side Bar For Non iPad Devices
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
        .onChange(of: props.isLandscape) { newValue in
            showSideBar = false
        }
    }
}
