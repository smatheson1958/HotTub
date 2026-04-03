//
//  HotTub_BuddyApp.swift
//  HotTub Buddy
//

import SwiftData
import SwiftUI

@main
struct HotTub_BuddyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(HotTubModelContainer.shared)
        }
    }
}
