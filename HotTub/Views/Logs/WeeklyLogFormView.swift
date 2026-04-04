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
    @Query private var settingsRows: [AppSettings]

    init(existing: WeeklyCheckLog? = nil) {
        self.existing = existing
    }

    private var shockOptions: [(String, String)] {
        settingsRows.first?.isBromine == true ? bromineShockOptions : chlorineShockOptions
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Date & time", selection: $loggedAt, displayedComponents: [.date, .hourAndMinute])
            } header: {
                Text("When")
            }

            Section {
                TextField("Combined sanitizer (ppm)", text: $combined)
                    .keyboardType(.decimalPad)
                TextField("Total sanitizer (ppm)", text: $total)
                    .keyboardType(.decimalPad)
                TextField("Total alkalinity", text: $alkalinity)
                    .keyboardType(.decimalPad)
                TextField("Copper (ppm)", text: $copper)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Water chemistry")
            }

            Section {
                TextField("Water clarity", text: $waterClarity, axis: .vertical)
                    .lineLimit(1 ... 3)
                Toggle("Foam present", isOn: $foamPresent)
            } header: {
                Text("Appearance")
            }

            Section {
                TextField("Shock added", text: $shock)
                    .keyboardType(.decimalPad)
                Picker("Shock type", selection: $shockType) {
                    Text("—").tag("")
                    ForEach(shockOptions, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                TextField("Alkalinity Up added", text: $alkUp)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Shock & adjustments")
            }

            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3 ... 6)
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.color(.backgroundSecondary))
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
            foamPresent: foamPresent
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
