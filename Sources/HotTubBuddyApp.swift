//
//  HotTubBuddyApp.swift
//  HotTub Buddy
//

import SwiftData
import SwiftUI

@main
struct HotTubBuddyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(HotTubModelContainer.shared)
        }
    }
}
