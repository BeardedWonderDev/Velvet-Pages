//
//  Sex_StoriesApp.swift
//  Sex Stories
//
//  Created by BoiseITGuru on 11/26/23.
//

import SwiftUI
import SwiftData

@main
struct Velvet_PagesApp: App {
    @StateObject private var scrapper = ScrapperViewModel()
    @StateObject private var appLock = AppLockViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ResponsiveView { props in
                    RouterView(props: props)
                        .environmentObject(scrapper)
                }
                .opacity(appLock.isLocked ? 0 : 1)
                .disabled(appLock.isLocked)

                if appLock.isLocked {
                    AppLockView()
                        .environmentObject(appLock)
                        .transition(.opacity)
                }
            }
            .task {
                appLock.configureForLaunch()
                appLock.isLocked = false
                await scrapper.loadLibraryIfNeeded(forceRefresh: false)
            }
            .onChange(of: scenePhase) { _, _ in
            }
        }
        .modelContainer(for: [CachedStoryRecord.self])
    }
}
