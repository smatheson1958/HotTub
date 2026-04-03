//
//  RateCalculator.swift
//  HotTub Buddy
//
//  Port of React rateCalculator.js for sanitizer consumption estimates.
//

import Foundation

struct UsageRatePeriod: Sendable {
    var periodStart: String
    var periodEnd: String
    var hoursElapsed: Double
    var daysElapsed: Double
    var ppmPerDay: Double
    var gramsPerDay: Double
    var excludedFromCalc: Bool
    var exclusionReason: String?
}

struct AverageRateResult: Sendable {
    var days: Int
    var sampleSize: Int
    var avgPpmPerDay: Double
    var avgGramsPerDay: Double
}

struct DataConfidence: Sendable {
    var hasRecentWaterChange: Bool
    var waterChangeDate: String?
    var daysSinceWaterChange: Int?
    var readingsSinceWaterChange: Int
    var confidence: String
    var warningMessage: String?
}

enum RateCalculator {
    private static func mostRecentWaterChangeDate(from maintenance: [MaintenanceLogEntry]) -> String? {
        maintenance
            .filter(\.waterChange)
            .sorted { a, b in
                if a.logDate != b.logDate { return a.logDate > b.logDate }
                return (a.logTime) > (b.logTime)
            }
            .first?
            .logDate
    }

    static func calculateUsageRates(
        logs: [HotTubDailyLog],
        volumeLitres: Double,
        weeklyChecks: [WeeklyCheckLog],
        maintenanceLogs: [MaintenanceLogEntry]
    ) -> [UsageRatePeriod] {
        guard logs.count >= 2 else { return [] }

        let waterChangeDate = mostRecentWaterChangeDate(from: maintenanceLogs)
        let filtered: [HotTubDailyLog]
        if let waterChangeDate {
            filtered = logs.filter { $0.logDate > waterChangeDate }
        } else {
            filtered = logs
        }
        guard filtered.count >= 2 else { return [] }

        let sortedLogs = filtered.sorted { a, b in
            if a.logDate != b.logDate { return a.logDate < b.logDate }
            return (a.logTime) < (b.logTime)
        }

        var rates: [UsageRatePeriod] = []
        let cal = Calendar(identifier: .gregorian)

        for i in 1..<sortedLogs.count {
            let before = sortedLogs[i - 1]
            let after = sortedLogs[i]
            guard let c1 = before.chlorine1, let c2 = after.chlorine1 else { continue }

            let beforeTime = dateFrom(logDate: before.logDate, logTime: before.logTime, calendar: cal)
            let afterTime = dateFrom(logDate: after.logDate, logTime: after.logTime, calendar: cal)
            guard let beforeTime, let afterTime else { continue }

            let hoursElapsed = afterTime.timeIntervalSince(beforeTime) / 3600
            if hoursElapsed <= 0 { continue }

            let chlorineShockInPeriod = weeklyChecks.contains { check in
                let d = check.logDate
                return d >= before.logDate && d <= after.logDate
                    && (check.shockAdded ?? 0) > 0
                    && ShockTypes.isSanitizerAddingShock(check.shockType)
            }

            let ppmChange = c1 - c2
            let ppmAdded = after.addedChlorine
            let totalConsumed = ppmChange + ppmAdded
            let ppmPerHour = totalConsumed / hoursElapsed
            let ppmPerDay = ppmPerHour * 24
            let gramsPerDay = (ppmPerDay * volumeLitres) / 1000 / 0.62

            rates.append(
                UsageRatePeriod(
                    periodStart: before.logDate,
                    periodEnd: after.logDate,
                    hoursElapsed: (hoursElapsed * 10).rounded() / 10,
                    daysElapsed: ((hoursElapsed / 24) * 10).rounded() / 10,
                    ppmPerDay: (ppmPerDay * 100).rounded() / 100,
                    gramsPerDay: (gramsPerDay * 100).rounded() / 100,
                    excludedFromCalc: chlorineShockInPeriod,
                    exclusionReason: chlorineShockInPeriod
                        ? "Chlorine-based shock applied in this period"
                        : nil
                )
            )
        }
        return rates
    }

    private static func dateFrom(logDate: String, logTime: String, calendar: Calendar) -> Date? {
        let t = logTime.count >= 5 ? String(logTime.prefix(5)) : logTime
        return parseFallback(date: logDate, time: t, calendar: calendar)
    }

    private static func parseFallback(date: String, time: String, calendar: Calendar) -> Date? {
        var dc = DateComponents()
        let dp = date.split(separator: "-").compactMap { Int($0) }
        guard dp.count == 3 else { return nil }
        dc.year = dp[0]
        dc.month = dp[1]
        dc.day = dp[2]
        let tp = time.split(separator: ":").compactMap { Int($0) }
        dc.hour = tp.first ?? 0
        dc.minute = tp.count > 1 ? tp[1] : 0
        return calendar.date(from: dc)
    }

    static func getCurrentRate(
        logs: [HotTubDailyLog],
        volumeLitres: Double,
        weeklyChecks: [WeeklyCheckLog],
        maintenanceLogs: [MaintenanceLogEntry]
    ) -> UsageRatePeriod? {
        let rates = calculateUsageRates(
            logs: logs,
            volumeLitres: volumeLitres,
            weeklyChecks: weeklyChecks,
            maintenanceLogs: maintenanceLogs
        )
        let valid = rates.filter { !$0.excludedFromCalc }
        return valid.last
    }

    static func getAverageRate(
        logs: [HotTubDailyLog],
        volumeLitres: Double,
        days: Int = 7,
        weeklyChecks: [WeeklyCheckLog],
        maintenanceLogs: [MaintenanceLogEntry]
    ) -> AverageRateResult? {
        let rates = calculateUsageRates(
            logs: logs,
            volumeLitres: volumeLitres,
            weeklyChecks: weeklyChecks,
            maintenanceLogs: maintenanceLogs
        )
        guard !rates.isEmpty else { return nil }

        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let cutoffStr = f.string(from: cutoff)

        let recent = rates.filter { $0.periodEnd >= cutoffStr && !$0.excludedFromCalc }
        guard !recent.isEmpty else { return nil }

        let avgPpm = recent.map(\.ppmPerDay).reduce(0, +) / Double(recent.count)
        let avgGrams = recent.map(\.gramsPerDay).reduce(0, +) / Double(recent.count)
        return AverageRateResult(
            days: days,
            sampleSize: recent.count,
            avgPpmPerDay: (avgPpm * 100).rounded() / 100,
            avgGramsPerDay: (avgGrams * 100).rounded() / 100
        )
    }

    static func getDataConfidence(
        logs: [HotTubDailyLog],
        maintenanceLogs: [MaintenanceLogEntry]
    ) -> DataConfidence {
        let waterChangeDate = mostRecentWaterChangeDate(from: maintenanceLogs)

        guard let waterChangeDate else {
            let n = logs.count
            let conf: String
            if n >= 7 { conf = "high" }
            else if n >= 3 { conf = "medium" }
            else { conf = "low" }
            return DataConfidence(
                hasRecentWaterChange: false,
                waterChangeDate: nil,
                daysSinceWaterChange: nil,
                readingsSinceWaterChange: n,
                confidence: conf,
                warningMessage: nil
            )
        }

        let logsAfter = logs.filter { $0.logDate > waterChangeDate }
        let wcDate = parseDateOnly(waterChangeDate)
        let daysSince: Int
        if let wcDate {
            daysSince = Calendar.current.dateComponents([.day], from: wcDate, to: Date()).day ?? 0
        } else {
            daysSince = 0
        }

        var confidence = "low"
        var warning: String?

        if logsAfter.count < 2 {
            confidence = "insufficient"
            warning = "Need at least 2 readings after water change for consumption estimates"
        } else if daysSince < 7 || logsAfter.count < 5 {
            confidence = "low"
            warning = "Recent water change - consumption rates may be less stable than normal"
        } else {
            confidence = "medium"
        }

        return DataConfidence(
            hasRecentWaterChange: true,
            waterChangeDate: waterChangeDate,
            daysSinceWaterChange: daysSince,
            readingsSinceWaterChange: logsAfter.count,
            confidence: confidence,
            warningMessage: warning
        )
    }

    private static func parseDateOnly(_ ymd: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: ymd)
    }
}
