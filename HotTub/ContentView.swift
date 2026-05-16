//
//  ContentView.swift
//  HotTub
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(DisclaimerAcceptance.storageKey) private var acceptedDisclaimerVersion = ""

    var body: some View {
        Group {
            if DisclaimerAcceptance.isAccepted(acceptedDisclaimerVersion) {
                MainTabView()
                    .onAppear {
                        HotTubModelContainer.seedIfNeeded(in: modelContext)
                    }
            } else {
                DisclaimerView {
                    acceptedDisclaimerVersion = DisclaimerAcceptance.currentVersion
                }
            }
        }
        .appPalette(colorScheme)
    }
}

private func makePreviewModelContainer() -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        return try ModelContainer(
            for: AppSettings.self,
            HotTubDailyLog.self,
            WeeklyCheckLog.self,
            MaintenanceLogEntry.self,
            UsageLogEntry.self,
            configurations: configuration
        )
    } catch {
        fatalError("Preview ModelContainer failed: \(error.localizedDescription)")
    }
}

private let previewSampleDailyLogNote = "Preview sample (Canvas only)"

private func seedPreviewSampleDailyLogs(into context: ModelContext) {
    let existing = (try? context.fetch(FetchDescriptor<HotTubDailyLog>())) ?? []
    for log in existing where log.notes == previewSampleDailyLogNote {
        context.delete(log)
    }

    let year = Calendar.current.component(.year, from: Date())
    let rows: [(Int, Double, Double, String)] = [
        (4, 7.08, 1.4, "09:10:00"),
        (8, 7.18, 2.6, "10:25:00"),
        (12, 7.28, 3.5, "08:45:00"),
        (20, 7.38, 4.2, "19:00:00"),
        (27, 7.48, 2.1, "07:30:00"),
    ]

    let cal = Calendar.current
    for (day, ph, chlorine, time) in rows {
        let tp = time.split(separator: ":").compactMap { Int($0) }
        var dc = DateComponents()
        dc.year = year
        dc.month = 3
        dc.day = day
        dc.hour = tp.first ?? 0
        dc.minute = tp.count > 1 ? tp[1] : 0
        dc.second = tp.count > 2 ? tp[2] : 0
        guard let loggedAt = cal.date(from: dc) else { continue }
        let log = HotTubDailyLog(
            loggedAt: loggedAt,
            waterTemperature: 37,
            ph: ph,
            sanitizerFree: chlorine,
            notes: previewSampleDailyLogNote
        )
        context.insert(log)
    }
    try? context.save()
}

private struct ContentViewPreviewHost: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ContentView()
            .onAppear {
                UserDefaults.standard.set(
                    DisclaimerAcceptance.currentVersion,
                    forKey: DisclaimerAcceptance.storageKey
                )
                HotTubModelContainer.seedIfNeeded(in: modelContext)
                seedPreviewSampleDailyLogs(into: modelContext)
            }
    }
}

#Preview {
    ContentViewPreviewHost()
        .modelContainer(makePreviewModelContainer())
        .appPalette(.light)
}
