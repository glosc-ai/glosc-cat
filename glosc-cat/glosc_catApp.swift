//
//  glosc_catApp.swift
//  glosc-cat
//
//  Created by XiaoM on 2026/3/21.
//

import SwiftUI
import SwiftData

@main
struct glosc_catApp: App {
    @StateObject private var languageStore = LanguageStore()

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
                .id(languageStore.currentLanguage.localeIdentifier)
        }
        .modelContainer(sharedModelContainer)
    }
}
