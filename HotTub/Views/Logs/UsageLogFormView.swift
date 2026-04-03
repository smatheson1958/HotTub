//
//  UsageLogFormView.swift
//  HotTub
//

import SwiftData
import SwiftUI

struct UsageLogFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let existing: UsageLogEntry?

    @State private var usageDate = LogFormFormatting.todayYMD()
    @State private var usageTime = LogFormFormatting.nowHM()
    @State private var numUsers = 1
    @State private var durationMinutes = 15

    @State private var alertMessage: String?
    @State private var showAlert = false

    init(existing: UsageLogEntry? = nil) {
        self.existing = existing
    }

    var body: some View {
        Form {
            Section {
                TextField("Date (yyyy-MM-dd)", text: $usageDate)
                TextField("Time (HH:mm)", text: $usageTime)
            } header: {
                Text("When")
            }

            Section {
                Stepper("People: \(numUsers)", value: $numUsers, in: 1 ... 20)
                Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 5 ... 480, step: 5)
            } header: {
                Text("Session")
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.color(.backgroundSecondary))
        .navigationTitle(existing == nil ? "Usage log" : "Edit usage")
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
                usageDate = e.usageDate
                usageTime = String(e.usageTime.prefix(5))
                numUsers = e.numUsers
                durationMinutes = e.durationMinutes
            }
        }
        .alert("Cannot save", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func save() {
        let errs = FormValidation.validateUsage(usageDate: usageDate)
        if !errs.isEmpty {
            alertMessage = errs.joined(separator: "\n")
            showAlert = true
            return
        }

        let t = usageTime.count == 5 ? "\(usageTime):00" : usageTime

        if let e = existing {
            e.usageDate = usageDate
            e.usageTime = t
            e.numUsers = numUsers
            e.durationMinutes = durationMinutes
        } else {
            let log = UsageLogEntry(
                usageDate: usageDate,
                usageTime: t,
                numUsers: numUsers,
                durationMinutes: durationMinutes
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
