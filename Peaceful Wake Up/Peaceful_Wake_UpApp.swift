//
//  Peaceful_Wake_UpApp.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/7/25.
//

import SwiftUI
import SwiftData

@main
struct Peaceful_Wake_UpApp: App {
    // MARK: - App Initialization
    init() {
        // Initialize app configuration and logging
        AppConfiguration.initialize()
        AppLogger.info("Peaceful Wake Up app starting", category: .system)
        
        // Setup dependency container
        DependencyContainer.shared.initialize()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            AppLogger.error("Could not create ModelContainer: \(error)", category: .system)
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppLogger.info("Main window appeared", category: .ui)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
