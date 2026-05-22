//
//  DailyLogFormView.swift
//  HotTub Buddy
//

import SwiftData
import SwiftUI

struct DailyLogFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let existing: HotTubDailyLog?

    @State private var loggedAt: Date = .now
    @State private var waterTemp: Int = 37
    @State private var ph: String = ""
    @State private var sanitizerFree: String = ""
    @State private var sanitizerCombined: String = ""
    @State private var addedSanitizer: String = ""
    @State private var addedPhUp: String = ""
    @State private var addedPhDown: String = ""
    @State private var notes: String = ""

    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var presentedHelp: HelpSheetRequest?
    @Query private var settingsRows: [AppSettings]

    private var isCelsius: Bool {
        settingsRows.first?.temperatureUnit != "fahrenheit"
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

    private var freeSanitizerPlaceholder: String {
        isBromine ? "3.0-5.0" : "1.0-3.0"
    }

    private var weightUnit: String {
        isMetric ? "g" : "oz"
    }

    init(existing: HotTubDailyLog? = nil) {
        self.existing = existing
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

                AppFormScreenSection(
                    title: "Temperature",
                    helpRequest: HelpSheetRequest(topic: .temperature),
                    presentedHelp: $presentedHelp
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "thermometer.medium")
                            .font(.body.weight(.medium))
                            .foregroundStyle(palette.color(.accentBlue))
                            .frame(width: 24, alignment: .center)
                        Stepper(
                            "Water \(isCelsius ? "°C" : "°F"): \(waterTemp)",
                            value: $waterTemp,
                            in: isCelsius ? 10 ... 45 : 50 ... 110,
                            step: 1
                        )
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.color(.textPrimary))
                    }
                    .frame(minHeight: AppSpacing.minTap)
                }

                AppFormScreenSection(title: "Chemical readings", presentedHelp: $presentedHelp) {
                    AppLabeledFormField(
                        title: "pH",
                        helpRequest: .ph(.overview),
                        presentedHelp: $presentedHelp,
                        systemImage: "flask",
                        placeholder: "7.2-7.8",
                        text: $ph
                    )
                    AppLabeledFormField(
                        title: isBromine ? "Bromine (ppm)" : "Free chlorine (ppm)",
                        helpRequest: .sanitizer(.free),
                        presentedHelp: $presentedHelp,
                        systemImage: "drop.fill",
                        placeholder: freeSanitizerPlaceholder,
                        text: $sanitizerFree
                    )
                    if !isBromine {
                        AppLabeledFormField(
                            title: "Combined chlorine (ppm)",
                            helpRequest: .sanitizer(.combined),
                            presentedHelp: $presentedHelp,
                            systemImage: "drop.triangle",
                            placeholder: "0.0-0.5",
                            text: $sanitizerCombined
                        )
                    }
                }

                AppFormScreenSection(
                    title: "Chemicals added",
                    helpRequest: HelpSheetRequest(topic: .chemicalsAdded),
                    presentedHelp: $presentedHelp
                ) {
                    AppSimpleMetricField(
                        title: "\(sanitizerName) added (\(weightUnit))",
                        systemImage: "bolt.fill",
                        placeholder: "0.0 \(weightUnit)",
                        text: $addedSanitizer
                    )
                    AppLabeledFormField(
                        title: "pH Down added (\(weightUnit))",
                        helpRequest: .ph(.down),
                        presentedHelp: $presentedHelp,
                        systemImage: "arrow.down.right",
                        placeholder: "0.0 \(weightUnit)",
                        text: $addedPhDown
                    )
                    AppLabeledFormField(
                        title: "pH Up added (\(weightUnit))",
                        helpRequest: .ph(.up),
                        presentedHelp: $presentedHelp,
                        systemImage: "arrow.up.right",
                        placeholder: "0.0 \(weightUnit)",
                        text: $addedPhUp
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
        .navigationTitle(existing == nil ? "Daily log" : "Edit daily log")
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
                if let t = e.waterTemperature { waterTemp = t }
                ph = e.ph.map { String(format: "%g", $0) } ?? ""
                sanitizerFree = e.sanitizerFree.map { String(format: "%g", $0) } ?? ""
                sanitizerCombined = e.sanitizerCombined.map { String(format: "%g", $0) } ?? ""
                addedSanitizer = e.addedSanitizer > 0 ? String(format: "%g", e.addedSanitizer) : ""
                addedPhUp = e.addedPhUp > 0 ? String(format: "%g", e.addedPhUp) : ""
                addedPhDown = e.addedPhDown > 0 ? String(format: "%g", e.addedPhDown) : ""
                notes = e.notes ?? ""
            } else {
                waterTemp = isCelsius ? 37 : 98
            }
        }
        .alert("Cannot save", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func save() {
        let errs = FormValidation.validateDailyLog(
            loggedAt: loggedAt,
            ph: ph,
            sanitizerFree: sanitizerFree,
            sanitizerCombined: sanitizerCombined,
            addedSanitizer: addedSanitizer,
            addedPhUp: addedPhUp,
            addedPhDown: addedPhDown,
            notes: notes,
            isBromine: isBromine
        )
        if !errs.isEmpty {
            alertMessage = errs.joined(separator: "\n")
            showAlert = true
            return
        }

        let phVal = Double(ph.trimmingCharacters(in: .whitespaces))
        let freeVal = Double(sanitizerFree.trimmingCharacters(in: .whitespaces))
        let combVal = Double(sanitizerCombined.trimmingCharacters(in: .whitespaces))

        if let e = existing {
            apply(to: e, phVal: phVal, freeVal: freeVal, combVal: combVal)
        } else {
            let log = HotTubDailyLog(
                loggedAt: loggedAt,
                waterTemperature: waterTemp,
                ph: phVal,
                sanitizerFree: freeVal,
                sanitizerCombined: combVal,
                addedPhUp: Double(addedPhUp) ?? 0,
                addedPhDown: Double(addedPhDown) ?? 0,
                addedSanitizer: Double(addedSanitizer) ?? 0,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(log)
        }
        try? modelContext.save()
        dismiss()
    }

    private func apply(to e: HotTubDailyLog, phVal: Double?, freeVal: Double?, combVal: Double?) {
        e.loggedAt = loggedAt
        e.waterTemperature = waterTemp
        e.ph = phVal
        e.sanitizerFree = freeVal
        e.sanitizerCombined = combVal
        e.addedPhUp = Double(addedPhUp) ?? 0
        e.addedPhDown = Double(addedPhDown) ?? 0
        e.addedSanitizer = Double(addedSanitizer) ?? 0
        e.notes = notes.isEmpty ? nil : notes
    }

    private func deleteLog() {
        guard let e = existing else { return }
        modelContext.delete(e)
        try? modelContext.save()
        dismiss()
    }
}
