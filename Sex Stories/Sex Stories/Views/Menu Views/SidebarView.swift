//
//  SidebarView.swift
//  Consensual Connections
//
//  Created by BoiseITGuru on 4/11/23.
//

import SwiftUI

struct SidebarView: View {
    @Namespace var animation
    @SceneStorage("selectedPage") var selectedPage: AppPages = .home
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 55, height: 55)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.pink, .teal)
                .padding(.bottom, 20)
            
            ForEach(AppPages.allCases, id: \.rawValue) { page in
                if page == .account {
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    Image(systemName: page.image)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 33, height: 33)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.pink, .teal)
                    
                    Text(page.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(selectedPage == page ? Color.pink : .black)
                .padding(.vertical, 13)
                .frame(width: 65)
                .background {
                    if selectedPage == page {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(Color.teal.opacity(0.4))
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        selectedPage = page
                    }
                }
            }
        }
        .padding(.vertical, 15)
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(width: 100)
        .background {
            Color.secondary.opacity(0.5)
                .ignoresSafeArea()
        }
    }
}
