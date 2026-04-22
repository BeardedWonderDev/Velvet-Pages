//
//  ResponsiveView.swift
//  ResponsiveUI
//
//  Created by BoiseITGuru on 3/29/23.
//

import SwiftUI

// MARK: Custom View Which WIll GIve Useful AppProperties for Adotable UI
struct ResponsiveView<Content: View>: View {
    var content: (AppProperties)-> Content
    
    init(@ViewBuilder content: @escaping (AppProperties)->Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let isLandscape = size.width > size.height
            let isiPad = UIDevice.current.userInterfaceIdiom == .pad
            let isMaxSplit = isSplit() && size.width < 400
            let properties = AppProperties(isLandscape: isLandscape, isiPad: isiPad, isSplit: isSplit(), isMaxSplit: isMaxSplit, size: size)
            
            content(properties)
                .frame(width: size.width, height: size.height)
        }
    }
    
    // MARK: Simple Way to Find if the app is in Split View
    func isSplit() -> Bool {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return false }

        return screen.windows.first?.frame.size != screen.screen.bounds.size
    }
}
