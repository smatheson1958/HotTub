//
//  SwiftDataModels.swift
//  HotTub Buddy
//
//  SwiftData persistence aligned with the React app’s AsyncStorage shapes
//  (daily logs, weekly checks, maintenance, usage, settings).
//

import Foundation
import SwiftData

// MARK: - App settings (single logical row; bootstrap ensures one instance)

@Model
final class AppSettings {
    var capacity: Double
    var capacityUnit: String
    var measurementSystem: String
    var sanitizerType: String
    var temperatureUnit: String
    var updatedAt: Date

    init(
        capacity: Double = 1000,
        capacityUnit: String = "liters",
        measurementSystem: String = "metric",
        sanitizerType: String = "chlorine",
        temperatureUnit: String = "celsius",
        updatedAt: Date = .now
    ) {
        self.capacity = capacity
        self.capacityUnit = capacityUnit
        self.measurementSystem = measurementSystem
        self.sanitizerType = sanitizerType
        self.temperatureUnit = temperatureUnit
        self.updatedAt = updatedAt
    }

    /// Volume in litres for calculators (matches React `volume_litres` fallback chain).
    var volumeLitres: Double {
        if capacityUnit.lowercased() == "liters" || capacityUnit.lowercased() == "litres" {
            return capacity
        }
        // imperial gallons → litres
        if capacityUnit.lowercased().contains("gallon") {
            return capacity * 3.78541
        }
        return capacity
    }

    var isBromine: Bool {
        sanitizerType.lowercased() == "bromine"
    }
}

// MARK: - Daily hot tub log

@Model
final class HotTubDailyLog {
    var logDate: String
    var logTime: String
    var createdAt: Date

    var waterTemperature: Int?

    var ph: Double?
    var sanitizerFree: Double?
    var sanitizerCombinedOrTotal: Double?

    /// Free / combined / total sanitizer readings (React `chlorine_1`…`chlorine_3`).
    var chlorine1: Double?
    var chlorine2: Double?
    var chlorine3: Double?

    var addedChlorine: Double
    var addedPhUp: Double
    var addedPhDown: Double
    var addedSanitizer: Double

    var notes: String?

    init(
        logDate: String,
        logTime: String,
        createdAt: Date = .now,
        waterTemperature: Int? = nil,
        ph: Double? = nil,
        sanitizerFree: Double? = nil,
        sanitizerCombinedOrTotal: Double? = nil,
        chlorine1: Double? = nil,
        chlorine2: Double? = nil,
        chlorine3: Double? = nil,
        addedChlorine: Double = 0,
        addedPhUp: Double = 0,
        addedPhDown: Double = 0,
        addedSanitizer: Double = 0,
        notes: String? = nil
    ) {
        self.logDate = logDate
        self.logTime = logTime
        self.createdAt = createdAt
        self.waterTemperature = waterTemperature
        self.ph = ph
        self.sanitizerFree = sanitizerFree
        self.sanitizerCombinedOrTotal = sanitizerCombinedOrTotal
        self.chlorine1 = chlorine1
        self.chlorine2 = chlorine2
        self.chlorine3 = chlorine3
        self.addedChlorine = addedChlorine
        self.addedPhUp = addedPhUp
        self.addedPhDown = addedPhDown
        self.addedSanitizer = addedSanitizer
        self.notes = notes
    }

    /// Primary ppm reading for consumption math (prefers `chlorine_1`, then free sanitizer).
    var primarySanitizerPpm: Double? {
        chlorine1 ?? sanitizerFree
    }
}

// MARK: - Weekly check

@Model
final class WeeklyCheckLog {
    var logDate: String
    var logTime: String
    var createdAt: Date

    var combinedChlorine: Double?
    var totalChlorine: Double?
    var totalAlkalinity: Double?
    var copper: Double?
    var shockAdded: Double?
    var shockType: String
    var alkalinityUpAdded: Double?
    var notes: String?

    init(
        logDate: String,
        logTime: String,
        createdAt: Date = .now,
        combinedChlorine: Double? = nil,
        totalChlorine: Double? = nil,
        totalAlkalinity: Double? = nil,
        copper: Double? = nil,
        shockAdded: Double? = nil,
        shockType: String = "",
        alkalinityUpAdded: Double? = nil,
        notes: String? = nil
    ) {
        self.logDate = logDate
        self.logTime = logTime
        self.createdAt = createdAt
        self.combinedChlorine = combinedChlorine
        self.totalChlorine = totalChlorine
        self.totalAlkalinity = totalAlkalinity
        self.copper = copper
        self.shockAdded = shockAdded
        self.shockType = shockType
        self.alkalinityUpAdded = alkalinityUpAdded
        self.notes = notes
    }
}

// MARK: - Maintenance

@Model
final class MaintenanceLogEntry {
    var logDate: String
    var logTime: String
    var createdAt: Date

    var action: String
    var notes: String
    var filterChanged: Bool
    var waterChange: Bool

    init(
        logDate: String,
        logTime: String,
        createdAt: Date = .now,
        action: String = "",
        notes: String = "",
        filterChanged: Bool = false,
        waterChange: Bool = false
    ) {
        self.logDate = logDate
        self.logTime = logTime
        self.createdAt = createdAt
        self.action = action
        self.notes = notes
        self.filterChanged = filterChanged
        self.waterChange = waterChange
    }
}

// MARK: - Usage

@Model
final class UsageLogEntry {
    var usageDate: String
    var usageTime: String
    var createdAt: Date

    var numUsers: Int
    var durationMinutes: Int

    init(
        usageDate: String,
        usageTime: String,
        createdAt: Date = .now,
        numUsers: Int = 1,
        durationMinutes: Int = 15
    ) {
        self.usageDate = usageDate
        self.usageTime = usageTime
        self.createdAt = createdAt
        self.numUsers = numUsers
        self.durationMinutes = durationMinutes
    }
}
