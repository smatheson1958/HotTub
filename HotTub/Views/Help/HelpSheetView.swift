//
//  HelpSheetView.swift
//  HotTub
//
//  Sheet host migrated from React `HelpModal.jsx`.
//

import SwiftUI

struct HelpSheetView: View {
    let topic: HelpTopic
    var isBromine: Bool
    var isMetric: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appPalette) private var palette

    var body: some View {
        NavigationStack {
            ScrollView {
                HelpTopicRouter(topic: topic, isBromine: isBromine, isMetric: isMetric)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
            .background(palette.color(.backgroundSecondary))
            .navigationTitle(topic.screenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct HelpTopicRouter: View {
    let topic: HelpTopic
    let isBromine: Bool
    let isMetric: Bool

    var body: some View {
        switch topic {
        case .ph:
            HelpPhContent()
        case .sanitizer:
            HelpSanitizerContent(isBromine: isBromine)
        case .copper:
            HelpCopperContent()
        case .alkalinity:
            HelpAlkalinityContent()
        case .temperature:
            HelpTemperatureContent()
        case .chemicalsAdded:
            HelpChemicalsAddedContent(isBromine: isBromine, isMetric: isMetric)
        case .shock:
            HelpShockContent(isBromine: isBromine, isMetric: isMetric)
        case .consumption:
            HelpConsumptionContent(isBromine: isBromine, isMetric: isMetric)
        case .general:
            HelpDefaultContent()
        }
    }
}
