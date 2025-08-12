//
//  ConstruAppApp.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import SwiftData

@main
struct ConstruAppApp: App {
    var sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            Project.self,
            Blueprint.self,
            LogEntry.self
        ])

        let isTesting = CommandLine.arguments.contains("-ui-testing")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isTesting)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            if isTesting {
                // Clear any existing data and create fresh sample data for tests
                try container.mainContext.delete(model: Project.self)
                _ = SampleDataManager.createSampleProject(in: container.mainContext)
            }

            self.sharedModelContainer = container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LocalizationManager.shared)
                .environmentObject(ThemeManager.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
