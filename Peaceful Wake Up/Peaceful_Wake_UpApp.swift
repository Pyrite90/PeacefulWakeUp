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
        // App initialization completed
        print("Peaceful Wake Up app starting")
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Could not create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
