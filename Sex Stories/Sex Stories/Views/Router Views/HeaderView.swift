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
    
    @SceneStorage("selectedPage") var selectedPage: AppPages = .home
    @SceneStorage("showSideBar") var showSideBar: Bool = false
    
    var body: some View {
        // MARK: Search Bar With Menu Button
        HStack(spacing: 10) {
            if !props.isiPad || (props.isiPad && !props.isLandscape) {
                Button {
                    withAnimation(.easeInOut) {
                        showSideBar.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 27, height: 27)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(scrapper.accentColor, scrapper.primaryColor)
                }
            }
            
            Spacer()
            
            Text(selectedPage.rawValue)
                .font(.title3.bold())
                .foregroundStyle(scrapper.primaryColor)
            
            Spacer()
            
            Button {
                
            } label: {
                Image(systemName: "bell.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 27, height: 27)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(scrapper.accentColor, scrapper.primaryColor)
            }
                
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(scrapper.backgroundColor.opacity(0.85))
        }
    }
}
