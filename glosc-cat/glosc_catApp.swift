//
//  glosc_catApp.swift
//  glosc-cat
//
//  Created by XiaoM on 2026/3/21.
//

import SwiftData
import SwiftUI

@main
struct glosc_catApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var appOpenAdManager = AppOpenAdManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            InteractionRecord.self,
            FavoritePhrase.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        AppLocalizationSupport.prepareForLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageStore)
                .environmentObject(appOpenAdManager)
                .overlay {
                    if appOpenAdManager.shouldShowLaunchOverlay {
                        AppLaunchOverlayView()
                            .transition(.opacity)
                    }
                }
                .task {
                    appOpenAdManager.startIfNeeded()
                }
                .id(languageStore.currentLanguage.localeIdentifier)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            appOpenAdManager.handleScenePhase(newPhase)
        }
    }
}
