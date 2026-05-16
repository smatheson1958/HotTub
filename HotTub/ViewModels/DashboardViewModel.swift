//
//  DashboardViewModel.swift
//  HotTub
//

import Combine
import Foundation
import SwiftData
import SwiftUI

enum DashboardActivity: Identifiable {
    case daily(HotTubDailyLog)
    case weekly(WeeklyCheckLog)
    case maintenance(MaintenanceLogEntry)
    case usage(UsageLogEntry)

    var id: PersistentIdentifier {
        switch self {
        case .daily(let x): x.persistentModelID
        case .weekly(let x): x.persistentModelID
        case .maintenance(let x): x.persistentModelID
        case .usage(let x): x.persistentModelID
        }
    }

    var sortMoment: Date {
        switch self {
        case .daily(let x): return x.loggedAt
        case .weekly(let x): return x.loggedAt
        case .maintenance(let x): return x.loggedAt
        case .usage(let x): return x.loggedAt
        }
    }

    var createdAtMoment: Date {
        switch self {
        case .daily(let x): return x.createdAt
        case .weekly(let x): return x.createdAt
        case .maintenance(let x): return x.createdAt
        case .usage(let x): return x.createdAt
        }
    }

    var title: String {
        switch self {
        case .daily: return "Daily Log"
        case .weekly: return "Weekly Check"
        case .maintenance(let x): return x.action.isEmpty ? "Maintenance" : x.action
        case .usage: return "Hot Tub Usage"
        }
    }

    var accentToken: PaletteToken {
        switch self {
        case .daily, .weekly: return .accentBlue
        case .maintenance: return .accentOrange
        case .usage: return .accentGreen
        }
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var latestDailyLog: HotTubDailyLog?
    @Published private(set) var recentActivity: [DashboardActivity] = []
    @Published private(set) var currentRate: UsageRatePeriod?
    @Published private(set) var averageRate: AverageRateResult?
    @Published private(set) var dataConfidence: DataConfidence?
    @Published private(set) var trendPercent: Double?
    @Published private(set) var trendUp: Bool?
    @Published private(set) var volumeLitres: Double = 1000
    @Published private(set) var isBromine: Bool = false
    @Published private(set) var weightUnit: String = "g"

    func reload(context: ModelContext) {
        HotTubModelContainer.seedIfNeeded(in: context)

        let daily = (try? context.fetch(FetchDescriptor<HotTubDailyLog>())) ?? []
        let weekly = (try? context.fetch(FetchDescriptor<WeeklyCheckLog>())) ?? []
        let maintenance = (try? context.fetch(FetchDescriptor<MaintenanceLogEntry>())) ?? []
        let usage = (try? context.fetch(FetchDescriptor<UsageLogEntry>())) ?? []
        let settingsList = (try? context.fetch(FetchDescriptor<AppSettings>())) ?? []
        let settings = settingsList.first

        let sortedDaily = daily.sorted { $0.loggedAt > $1.loggedAt }
        latestDailyLog = sortedDaily.first

        volumeLitres = settings?.volumeLitres ?? 1000
        isBromine = settings?.isBromine ?? false
        let metric = settings?.measurementSystem != "imperial"
        weightUnit = metric ? "g" : "oz"

        var combined: [DashboardActivity] = []
        combined.append(contentsOf: daily.map { .daily($0) })
        combined.append(contentsOf: weekly.map { .weekly($0) })
        combined.append(contentsOf: maintenance.map { .maintenance($0) })
        combined.append(contentsOf: usage.map { .usage($0) })

        combined.sort { a, b in
            if a.sortMoment != b.sortMoment { return a.sortMoment > b.sortMoment }
            return a.createdAtMoment > b.createdAtMoment
        }
        recentActivity = Array(combined.prefix(4))

        let sortedDailyAsc = daily.sorted { $0.loggedAt < $1.loggedAt }

        currentRate = RateCalculator.getCurrentRate(
            logs: sortedDailyAsc,
            volumeLitres: volumeLitres,
            weeklyChecks: weekly,
            maintenanceLogs: maintenance,
            isBromine: isBromine
        )
        averageRate = RateCalculator.getAverageRate(
            logs: sortedDailyAsc,
            volumeLitres: volumeLitres,
            days: 7,
            weeklyChecks: weekly,
            maintenanceLogs: maintenance,
            isBromine: isBromine
        )
        dataConfidence = RateCalculator.getDataConfidence(
            logs: sortedDailyAsc,
            maintenanceLogs: maintenance
        )

        trendPercent = nil
        trendUp = nil
        if let cur = currentRate, let avg = averageRate, avg.avgGramsPerDay > 0 {
            let pct = ((cur.gramsPerDay - avg.avgGramsPerDay) / avg.avgGramsPerDay) * 100
            if pct > 5 {
                trendUp = true
                trendPercent = abs((pct * 10).rounded() / 10)
            } else if pct < -5 {
                trendUp = false
                trendPercent = abs((pct * 10).rounded() / 10)
            }
        }
    }

    func delete(_ item: DashboardActivity, context: ModelContext) {
        switch item {
        case .daily(let l): context.delete(l)
        case .weekly(let l): context.delete(l)
        case .maintenance(let l): context.delete(l)
        case .usage(let l): context.delete(l)
        }
        try? context.save()
        reload(context: context)
    }

    func statusText(ph: Double?, sanitizer: Double?) -> String {
        if ph == nil && sanitizer == nil { return "No data" }
        let phOk = ph.map { $0 >= 7.2 && $0 <= 7.8 } ?? false
        let clOk: Bool
        if isBromine {
            clOk = sanitizer.map { $0 >= 3.0 && $0 <= 5.0 } ?? false
        } else {
            clOk = sanitizer.map { $0 >= 1.0 && $0 <= 3.0 } ?? false
        }
        if phOk && clOk { return "Balanced" }
        if !phOk && !clOk { return "Check pH & \(isBromine ? "Bromine" : "Chlorine")" }
        if !phOk { return "Check pH Level" }
        return "Check \(isBromine ? "Bromine" : "Chlorine")"
    }

    func sanitizerOutOfRange(_ ppm: Double?) -> Bool {
        guard let ppm else { return false }
        if isBromine { return ppm < 3.0 || ppm > 5.0 }
        return ppm < 1.0 || ppm > 3.0
    }

    func phOutOfRange(_ ph: Double?) -> Bool {
        guard let ph else { return false }
        return ph < 7.2 || ph > 7.8
    }
}
