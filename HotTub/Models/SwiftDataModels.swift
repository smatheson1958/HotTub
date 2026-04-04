//
//  SwiftDataModels.swift
//  HotTub
//

import Foundation
import SwiftData

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

    var volumeLitres: Double {
        if capacityUnit.lowercased() == "liters" || capacityUnit.lowercased() == "litres" {
            return capacity
        }
        if capacityUnit.lowercased().contains("gallon") {
            return capacity * 3.78541
        }
        return capacity
    }

    var isBromine: Bool {
        sanitizerType.lowercased() == "bromine"
    }
}

@Model
final class HotTubDailyLog {
    /// When the reading was taken (date and time).
    var loggedAt: Date
    var createdAt: Date

    var waterTemperature: Int?

    var ph: Double?
    var sanitizerFree: Double?
    var sanitizerCombined: Double?

    var addedPhUp: Double
    var addedPhDown: Double
    var addedSanitizer: Double

    var notes: String?

    init(
        loggedAt: Date,
        createdAt: Date = .now,
        waterTemperature: Int? = nil,
        ph: Double? = nil,
        sanitizerFree: Double? = nil,
        sanitizerCombined: Double? = nil,
        addedPhUp: Double = 0,
        addedPhDown: Double = 0,
        addedSanitizer: Double = 0,
        notes: String? = nil
    ) {
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.waterTemperature = waterTemperature
        self.ph = ph
        self.sanitizerFree = sanitizerFree
        self.sanitizerCombined = sanitizerCombined
        self.addedPhUp = addedPhUp
        self.addedPhDown = addedPhDown
        self.addedSanitizer = addedSanitizer
        self.notes = notes
    }

    var primarySanitizerPpm: Double? {
        sanitizerFree
    }
}

@Model
final class WeeklyCheckLog {
    var loggedAt: Date
    var createdAt: Date

    var combinedChlorine: Double?
    /// Total sanitizer reading (ppm), e.g. total chlorine or total bromine on weekly check.
    var sanitizerTotal: Double?
    var totalAlkalinity: Double?
    var copper: Double?
    var shockAdded: Double?
    var shockType: String
    var alkalinityUpAdded: Double?
    var notes: String?

    /// Free-text water clarity (e.g. clear, hazy).
    var waterClarity: String
    /// Whether foam was present on inspection.
    var foamPresent: Bool

    init(
        loggedAt: Date,
        createdAt: Date = .now,
        combinedChlorine: Double? = nil,
        sanitizerTotal: Double? = nil,
        totalAlkalinity: Double? = nil,
        copper: Double? = nil,
        shockAdded: Double? = nil,
        shockType: String = "",
        alkalinityUpAdded: Double? = nil,
        notes: String? = nil,
        waterClarity: String = "",
        foamPresent: Bool = false
    ) {
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.combinedChlorine = combinedChlorine
        self.sanitizerTotal = sanitizerTotal
        self.totalAlkalinity = totalAlkalinity
        self.copper = copper
        self.shockAdded = shockAdded
        self.shockType = shockType
        self.alkalinityUpAdded = alkalinityUpAdded
        self.notes = notes
        self.waterClarity = waterClarity
        self.foamPresent = foamPresent
    }
}

@Model
final class MaintenanceLogEntry {
    var loggedAt: Date
    var createdAt: Date

    var action: String
    var notes: String
    var filterChanged: Bool
    var waterChange: Bool

    init(
        loggedAt: Date,
        createdAt: Date = .now,
        action: String = "",
        notes: String = "",
        filterChanged: Bool = false,
        waterChange: Bool = false
    ) {
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.action = action
        self.notes = notes
        self.filterChanged = filterChanged
        self.waterChange = waterChange
    }
}

@Model
final class UsageLogEntry {
    var loggedAt: Date
    var createdAt: Date

    var numUsers: Int
    var durationMinutes: Int

    init(
        loggedAt: Date,
        createdAt: Date = .now,
        numUsers: Int = 1,
        durationMinutes: Int = 15
    ) {
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.numUsers = numUsers
        self.durationMinutes = durationMinutes
    }
}
