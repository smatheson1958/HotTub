//
//  ShockTypes.swift
//  HotTub
//

import Foundation

enum ShockTypes {
    static let sanitizerAdding: Set<String> = [
        "cal-hypo",
        "dichlor",
        "lithium-hypo",
        "bromine-granules",
    ]

    static func isSanitizerAddingShock(_ shockType: String?) -> Bool {
        guard let shockType, !shockType.isEmpty else { return false }
        return sanitizerAdding.contains(shockType)
    }
}
