//
//  MaintenanceLogFormView.swift
//  HotTub
//

import SwiftData
import SwiftUI

struct MaintenanceLogFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let existing: MaintenanceLogEntry?

    @State private var loggedAt: Date = .now
    @State private var action = ""
    @State private var notes = ""
    @State private var filterChanged = false
    @State private var waterChange = false

    @State private var alertMessage: String?
    @State private var showAlert = false

    init(existing: MaintenanceLogEntry? = nil) {
        self.existing = existing
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Date & time", selection: $loggedAt, displayedComponents: [.date, .hourAndMinute])
            } header: {
                Text("When")
            }

            Section {
                TextField("Action", text: $action, axis: .vertical)
                    .lineLimit(2 ... 4)
                Toggle("Water change", isOn: $waterChange)
                Toggle("Filter changed", isOn: $filterChanged)
            } header: {
                Text("Maintenance")
            }

            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3 ... 6)
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.color(.backgroundSecondary))
        .navigationTitle(existing == nil ? "Maintenance" : "Edit maintenance")
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
                action = e.action
                notes = e.notes
                filterChanged = e.filterChanged
                waterChange = e.waterChange
            }
        }
        .alert("Cannot save", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func save() {
        var finalAction = action.trimmingCharacters(in: .whitespaces)
        if finalAction.isEmpty {
            var parts: [String] = []
            if waterChange { parts.append("Water change") }
            if filterChanged { parts.append("Filter changed") }
            finalAction = parts.joined(separator: ", ")
        }

        let errs = FormValidation.validateMaintenance(
            loggedAt: loggedAt,
            action: finalAction,
            waterChange: waterChange,
            filterChanged: filterChanged
        )
        if !errs.isEmpty {
            alertMessage = errs.joined(separator: "\n")
            showAlert = true
            return
        }

        if let e = existing {
            e.loggedAt = loggedAt
            e.action = finalAction
            e.notes = notes
            e.filterChanged = filterChanged
            e.waterChange = waterChange
        } else {
            let log = MaintenanceLogEntry(
                loggedAt: loggedAt,
                action: finalAction,
                notes: notes,
                filterChanged: filterChanged,
                waterChange: waterChange
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
