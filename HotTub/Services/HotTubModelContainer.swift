//
//  HotTubModelContainer.swift
//  HotTub
//

import Foundation
import SwiftData

enum HotTubModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(
                for: AppSettings.self,
                HotTubDailyLog.self,
                WeeklyCheckLog.self,
                MaintenanceLogEntry.self,
                UsageLogEntry.self
            )
        } catch {
            fatalError("SwiftData container failed: \(error.localizedDescription)")
        }
    }()

    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        var descriptor = FetchDescriptor<AppSettings>()
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.isEmpty {
            context.insert(AppSettings())
            try? context.save()
        }
    }
}
