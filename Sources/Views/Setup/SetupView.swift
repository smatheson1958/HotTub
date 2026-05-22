//
//  SetupView.swift
//  HotTub Buddy
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
        .appGroupedScreenBackground(palette)
        .navigationTitle("Setup")
        .navigationBarTitleDisplayMode(.large)
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
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                hotTubSection
                volumeSection
                legalSection
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.screenTop)
            .padding(.bottom, AppSpacing.screenBottom)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var hotTubSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.control) {
            AppSectionHeader(
                title: "Hot tub",
                subtitle: "Capacity, units, and sanitizer type"
            )

            VStack(spacing: 0) {
                AppSettingsLabeledRow(label: "Capacity") {
                    TextField("1000", value: $settings.capacity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                        .onChange(of: settings.capacity) { _, _ in touch() }
                }

                AppSettingsDivider()

                AppSettingsLabeledRow(label: "Unit") {
                    Picker("Unit", selection: $settings.capacityUnit) {
                        Text("Litres").tag("liters")
                        Text("UK Gallons").tag("uk_gallons")
                        Text("US Gallons").tag("us_gallons")
                    }
                    .labelsHidden()
                    .onChange(of: settings.capacityUnit) { _, _ in touch() }
                }

                AppSettingsDivider()

                AppSettingsLabeledRow(label: "Measurements") {
                    Picker("Measurements", selection: $settings.measurementSystem) {
                        Text("Metric").tag("metric")
                        Text("Imperial").tag("imperial")
                    }
                    .labelsHidden()
                    .onChange(of: settings.measurementSystem) { _, _ in touch() }
                }

                AppSettingsDivider()

                AppSettingsLabeledRow(label: "Sanitizer") {
                    Picker("Sanitizer", selection: $settings.sanitizerType) {
                        Text("Chlorine").tag("chlorine")
                        Text("Bromine").tag("bromine")
                    }
                    .labelsHidden()
                    .onChange(of: settings.sanitizerType) { _, _ in touch() }
                }
            }
            .appCard(palette: palette, padding: 0)
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.control) {
            AppSectionHeader(
                title: "Volume",
                subtitle: "Stored with your tub settings for future reference"
            )

            AppSettingsValueRow(
                label: "Estimated litres",
                value: String(format: "%.0f L", settings.volumeLitres)
            )
            .appCard(palette: palette, padding: 0)
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.control) {
            AppSectionHeader(
                title: "Legal",
                subtitle: "Important information about using this app"
            )

            SetupDisclaimerView()
        }
    }

    private func touch() {
        settings.updatedAt = .now
        settings.temperatureUnit = settings.measurementSystem == "metric" ? "celsius" : "fahrenheit"
        try? modelContext.save()
    }
}
