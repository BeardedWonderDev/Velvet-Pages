//
//  Sex_StoriesApp.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//

import SwiftUI

@main
struct Sex_StoriesApp: App {
    @StateObject private var scrapper = ScrapperViewModel()
    
    var body: some Scene {
        WindowGroup {
            ResponsiveView { props in
                RouterView(props: props)
                    .environmentObject(scrapper)
            }
        }
    }
}
