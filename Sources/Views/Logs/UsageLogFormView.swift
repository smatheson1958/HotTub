//
//  UsageLogFormView.swift
//  HotTub Buddy
//

import SwiftData
import SwiftUI

struct UsageLogFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let existing: UsageLogEntry?

    @State private var loggedAt: Date = .now
    @State private var numUsers = 1
    @State private var durationMinutes = 15

    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var draftRecord: UsageLogEntry?
    @State private var autoSaveScheduler = FormAutoSaveScheduler()
    @State private var skipAutoSave = true
    @State private var baselineNumUsers = 1
    @State private var baselineDurationMinutes = 15

    init(existing: UsageLogEntry? = nil) {
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
                Button("Done") { finish() }
            }
            if activeRecord != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) { deleteLog() }
                }
            }
        }
        .onAppear {
            HotTubModelContainer.seedIfNeeded(in: modelContext)
            if let e = existing {
                loggedAt = e.loggedAt
                numUsers = e.numUsers
                durationMinutes = e.durationMinutes
                baselineNumUsers = e.numUsers
                baselineDurationMinutes = e.durationMinutes
            } else {
                baselineNumUsers = numUsers
                baselineDurationMinutes = durationMinutes
            }
            skipAutoSave = false
        }
        .onChange(of: formSnapshot) { _, _ in scheduleAutoSave() }
        .onDisappear {
            autoSaveScheduler.flush { persistDraft() }
            if existing == nil, let draft = draftRecord, isEmptyDraft(draft) {
                modelContext.delete(draft)
                try? modelContext.save()
            }
        }
        .alert("Cannot save", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var activeRecord: UsageLogEntry? {
        existing ?? draftRecord
    }

    private var formSnapshot: UsageFormSnapshot {
        UsageFormSnapshot(
            loggedAt: loggedAt,
            numUsers: numUsers,
            durationMinutes: durationMinutes
        )
    }

    private var hasDraftContent: Bool {
        existing != nil || numUsers != baselineNumUsers || durationMinutes != baselineDurationMinutes
    }

    private func scheduleAutoSave() {
        guard !skipAutoSave else { return }
        autoSaveScheduler.schedule { persistDraft() }
    }

    @discardableResult
    private func persistDraft() -> Bool {
        guard hasDraftContent else { return true }

        let record: UsageLogEntry
        if let existing {
            record = existing
        } else if let draftRecord {
            record = draftRecord
        } else {
            let log = UsageLogEntry(
                loggedAt: loggedAt,
                numUsers: numUsers,
                durationMinutes: durationMinutes
            )
            modelContext.insert(log)
            draftRecord = log
            record = log
        }

        record.loggedAt = loggedAt
        record.numUsers = numUsers
        record.durationMinutes = durationMinutes
        try? modelContext.save()
        return true
    }

    private func finish() {
        let errs = FormValidation.validateUsage(loggedAt: loggedAt)
        if !errs.isEmpty {
            alertMessage = errs.joined(separator: "\n")
            showAlert = true
            return
        }

        autoSaveScheduler.flush { persistDraft() }
        dismiss()
    }

    private func isEmptyDraft(_ record: UsageLogEntry) -> Bool {
        record.numUsers == baselineNumUsers && record.durationMinutes == baselineDurationMinutes
    }

    private func deleteLog() {
        guard let record = activeRecord else { return }
        modelContext.delete(record)
        try? modelContext.save()
        dismiss()
    }
}

private struct UsageFormSnapshot: Equatable {
    var loggedAt: Date
    var numUsers: Int
    var durationMinutes: Int
}
