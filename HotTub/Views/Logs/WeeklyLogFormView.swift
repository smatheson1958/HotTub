//
//  WeeklyLogFormView.swift
//  HotTub
//

import SwiftData
import SwiftUI

private let chlorineShockOptions: [(String, String)] = [
    ("Cal-Hypo", "cal-hypo"),
    ("Dichlor", "dichlor"),
    ("Lithium hypochlorite", "lithium-hypo"),
    ("Non-chlorine (MPS)", "mps"),
]

private let bromineShockOptions: [(String, String)] = [
    ("Non-chlorine (MPS)", "mps"),
    ("Bromine granules", "bromine-granules"),
]

struct WeeklyLogFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let existing: WeeklyCheckLog?

    @State private var loggedAt: Date = .now
    @State private var combined = ""
    @State private var total = ""
    @State private var alkalinity = ""
    @State private var copper = ""
    @State private var shock = ""
    @State private var shockType = ""
    @State private var alkUp = ""
    @State private var waterClarity = ""
    @State private var foamPresent = false
    @State private var notes = ""

    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var presentedHelp: HelpSheetRequest?
    @Query private var settingsRows: [AppSettings]

    init(existing: WeeklyCheckLog? = nil) {
        self.existing = existing
    }

    private var shockOptions: [(String, String)] {
        isBromine ? bromineShockOptions : chlorineShockOptions
    }

    private var isBromine: Bool {
        settingsRows.first?.isBromine ?? false
    }

    private var isMetric: Bool {
        settingsRows.first?.measurementSystem != "imperial"
    }

    private var sanitizerName: String {
        isBromine ? "Bromine" : "Chlorine"
    }

    private var weightUnit: String {
        isMetric ? "g" : "oz"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppFormScreenSection(title: "When", presentedHelp: $presentedHelp) {
                    DatePicker(
                        "Date & time",
                        selection: $loggedAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                AppFormScreenSection(title: "Water chemistry", presentedHelp: $presentedHelp) {
                    AppLabeledFormField(
                        title: "Combined \(sanitizerName.lowercased()) (ppm)",
                        helpRequest: .sanitizer(.combined),
                        presentedHelp: $presentedHelp,
                        systemImage: "drop.triangle",
                        placeholder: "0.0-0.5",
                        text: $combined
                    )
                    AppLabeledFormField(
                        title: "Total \(sanitizerName.lowercased()) (ppm)",
                        helpRequest: .sanitizer(.total),
                        presentedHelp: $presentedHelp,
                        systemImage: "drop.fill",
                        placeholder: isBromine ? "3.0-5.0" : "1.0-3.0",
                        text: $total
                    )
                    AppLabeledFormField(
                        title: "Total alkalinity (ppm)",
                        helpRequest: HelpSheetRequest(topic: .alkalinity),
                        presentedHelp: $presentedHelp,
                        systemImage: "aqi.medium",
                        placeholder: "80-120",
                        text: $alkalinity
                    )
                    AppLabeledFormField(
                        title: "Copper (ppm)",
                        helpRequest: HelpSheetRequest(topic: .copper),
                        presentedHelp: $presentedHelp,
                        systemImage: "circle.hexagongrid",
                        placeholder: "0.0-0.3",
                        text: $copper
                    )
                }

                AppFormScreenSection(title: "Appearance", presentedHelp: $presentedHelp) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Water clarity")
                            .font(.subheadline)
                            .foregroundStyle(palette.color(.textSecondary))
                        TextField("Clear, cloudy, etc.", text: $waterClarity, axis: .vertical)
                            .lineLimit(1 ... 3)
                            .font(.body)
                            .foregroundStyle(palette.color(.textPrimary))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minHeight: 50, alignment: .topLeading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(palette.color(.backgroundSecondary))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(palette.color(.separator).opacity(0.5), lineWidth: 1)
                            }
                    }
                    Toggle("Foam present", isOn: $foamPresent)
                        .font(.body)
                        .tint(palette.color(.accentBlue))
                        .padding(.top, 4)
                }

                AppFormScreenSection(
                    title: "Shock & adjustments",
                    helpRequest: HelpSheetRequest(topic: .shock),
                    presentedHelp: $presentedHelp
                ) {
                    AppSimpleMetricField(
                        title: "Shock added (\(weightUnit))",
                        systemImage: "bolt.fill",
                        placeholder: "0.0 \(weightUnit)",
                        text: $shock
                    )
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shock type")
                            .font(.subheadline)
                            .foregroundStyle(palette.color(.textSecondary))
                        Picker("Shock type", selection: $shockType) {
                            Text("—").tag("")
                            ForEach(shockOptions, id: \.1) { label, value in
                                Text(label).tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.color(.textPrimary))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 50)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(palette.color(.backgroundSecondary))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(palette.color(.separator).opacity(0.5), lineWidth: 1)
                        }
                    }
                    AppLabeledFormField(
                        title: "Alkalinity Up added (\(weightUnit))",
                        helpRequest: HelpSheetRequest(topic: .alkalinity),
                        presentedHelp: $presentedHelp,
                        systemImage: "arrow.up.circle",
                        placeholder: "0.0 \(weightUnit)",
                        text: $alkUp
                    )
                }

                AppFormScreenSection(title: "Notes", presentedHelp: $presentedHelp) {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                        .font(.body)
                        .foregroundStyle(palette.color(.textPrimary))
                        .frame(minHeight: 88, alignment: .topLeading)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.screenTop)
            .padding(.bottom, AppSpacing.screenBottom)
        }
        .scrollDismissesKeyboard(.interactively)
        .appGroupedScreenBackground(palette)
        .navigationTitle(existing == nil ? "Weekly check" : "Edit weekly check")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
            if existing != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) { deleteLog() }
                }
            }
        }
        .helpSheet(presentedHelp: $presentedHelp, isBromine: isBromine, isMetric: isMetric)
        .onAppear {
            HotTubModelContainer.seedIfNeeded(in: modelContext)
            if let e = existing {
                loggedAt = e.loggedAt
                combined = e.combinedChlorine.map { String(format: "%g", $0) } ?? ""
                total = e.sanitizerTotal.map { String(format: "%g", $0) } ?? ""
                alkalinity = e.totalAlkalinity.map { String(format: "%g", $0) } ?? ""
                copper = e.copper.map { String(format: "%g", $0) } ?? ""
                shock = (e.shockAdded ?? 0) > 0 ? String(format: "%g", e.shockAdded!) : ""
                shockType = e.shockType
                alkUp = (e.alkalinityUpAdded ?? 0) > 0 ? String(format: "%g", e.alkalinityUpAdded!) : ""
                waterClarity = e.waterClarity
                foamPresent = e.foamPresent
                notes = e.notes ?? ""
            }
        }
        .alert("Cannot save", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func save() {
        let errs = FormValidation.validateWeekly(
            loggedAt: loggedAt,
            combined: combined,
            total: total,
            alkalinity: alkalinity,
            copper: copper,
            shock: shock,
            alkUp: alkUp,
            notes: notes,
            waterClarity: waterClarity,
            foamPresent: foamPresent,
            isBromine: isBromine
        )
        if !errs.isEmpty {
            alertMessage = errs.joined(separator: "\n")
            showAlert = true
            return
        }

        let shockVal = Double(shock.trimmingCharacters(in: .whitespaces)) ?? 0

        if let e = existing {
            e.loggedAt = loggedAt
            e.combinedChlorine = Double(combined.trimmingCharacters(in: .whitespaces))
            e.sanitizerTotal = Double(total.trimmingCharacters(in: .whitespaces))
            e.totalAlkalinity = Double(alkalinity.trimmingCharacters(in: .whitespaces))
            e.copper = Double(copper.trimmingCharacters(in: .whitespaces))
            e.shockAdded = shockVal
            e.shockType = shockType
            e.alkalinityUpAdded = Double(alkUp.trimmingCharacters(in: .whitespaces)) ?? 0
            e.waterClarity = waterClarity.trimmingCharacters(in: .whitespaces)
            e.foamPresent = foamPresent
            e.notes = notes.isEmpty ? nil : notes
        } else {
            let log = WeeklyCheckLog(
                loggedAt: loggedAt,
                combinedChlorine: Double(combined.trimmingCharacters(in: .whitespaces)),
                sanitizerTotal: Double(total.trimmingCharacters(in: .whitespaces)),
                totalAlkalinity: Double(alkalinity.trimmingCharacters(in: .whitespaces)),
                copper: Double(copper.trimmingCharacters(in: .whitespaces)),
                shockAdded: shockVal,
                shockType: shockType,
                alkalinityUpAdded: Double(alkUp.trimmingCharacters(in: .whitespaces)) ?? 0,
                notes: notes.isEmpty ? nil : notes,
                waterClarity: waterClarity.trimmingCharacters(in: .whitespaces),
                foamPresent: foamPresent
            )
            modelContext.insert(log)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteLog() {
        guard let e = existing else { return }
        modelContext.delete(e)
        try? modelContext.save()
        dismiss()
    }
}
