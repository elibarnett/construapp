//
//  ContentView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ProjectListView()
            .handleAppearanceChanges()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}
