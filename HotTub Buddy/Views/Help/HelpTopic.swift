//
//  HelpTopic.swift
//  HotTub Buddy
//

import Foundation

/// Topics aligned with React `HelpModal` (`HelpModal.jsx`).
enum HelpTopic: String, CaseIterable, Identifiable, Hashable {
    case ph
    case sanitizer
    case copper
    case alkalinity
    case temperature
    case chemicalsAdded
    case shock
    case consumption
    case general

    var id: String { rawValue }

    /// Navigation / sheet title (matches React `getTitle` where applicable).
    var screenTitle: String {
        switch self {
        case .ph: return "pH & Alkalinity Guide"
        case .sanitizer: return "Sanitizer Guide"
        case .copper: return "Copper (Cu) Guide"
        case .alkalinity: return "Total Alkalinity Guide"
        case .temperature: return "Temperature Guide"
        case .chemicalsAdded: return "Chemicals Added Guide"
        case .shock: return "Shock Treatment Guide"
        case .consumption: return "Sanitizer Consumption Guide"
        case .general: return "Help & Guide"
        }
    }
}
