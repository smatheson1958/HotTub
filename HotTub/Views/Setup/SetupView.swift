//
//  SetupView.swift
//  HotTub
//

import SwiftData
import SwiftUI

struct SetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRows: [AppSettings]
    @Environment(\.appPalette) private var palette

    var body: some View {
        Group {
            if let settings = settingsRows.first {
                SetupSettingsForm(settings: settings)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(palette.color(.backgroundSecondary))
        .navigationTitle("Setup")
        .onAppear {
            HotTubModelContainer.seedIfNeeded(in: modelContext)
        }
    }
}

private struct SetupSettingsForm: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette

    var body: some View {
        Form {
            Section {
                TextField("Capacity", value: $settings.capacity, format: .number)
                    .keyboardType(.decimalPad)
                    .onChange(of: settings.capacity) { _, _ in touch() }

                Picker("Unit", selection: $settings.capacityUnit) {
                    Text("Litres").tag("liters")
                    Text("UK Gallons").tag("uk_gallons")
                    Text("US Gallons").tag("us_gallons")
                }
                .onChange(of: settings.capacityUnit) { _, _ in touch() }

                Picker("Measurements", selection: $settings.measurementSystem) {
                    Text("Metric").tag("metric")
                    Text("Imperial").tag("imperial")
                }
                .onChange(of: settings.measurementSystem) { _, _ in touch() }

                Picker("Sanitizer", selection: $settings.sanitizerType) {
                    Text("Chlorine").tag("chlorine")
                    Text("Bromine").tag("bromine")
                }
                .onChange(of: settings.sanitizerType) { _, _ in touch() }
            } header: {
                Text("Hot tub")
            }

            Section {
                LabeledContent("Volume (est. litres)", value: String(format: "%.0f", settings.volumeLitres))
            } footer: {
                Text("Used for consumption estimates on the dashboard.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.color(.backgroundSecondary))
    }

    private func touch() {
        settings.updatedAt = .now
        settings.temperatureUnit = settings.measurementSystem == "metric" ? "celsius" : "fahrenheit"
        try? modelContext.save()
    }
}
