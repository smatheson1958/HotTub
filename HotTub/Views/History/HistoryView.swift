//
//  HistoryView.swift
//  HotTub
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette

    @Query(sort: \HotTubDailyLog.logDate, order: .reverse) private var dailyLogs: [HotTubDailyLog]
    @Query(sort: \WeeklyCheckLog.logDate, order: .reverse) private var weeklyLogs: [WeeklyCheckLog]
    @Query(sort: \MaintenanceLogEntry.logDate, order: .reverse) private var maintenanceLogs: [MaintenanceLogEntry]
    @Query(sort: \UsageLogEntry.usageDate, order: .reverse) private var usageLogs: [UsageLogEntry]
    @Query private var settingsRows: [AppSettings]

    @State private var filterDaily = true
    @State private var filterWeekly = true
    @State private var filterMaintenance = true
    @State private var filterUsage = true
    @State private var deleteTarget: HistoryRow?
    @State private var showDeleteConfirm = false

    private var isBromine: Bool {
        settingsRows.first?.isBromine ?? false
    }

    private var combinedRows: [HistoryRow] {
        var rows: [HistoryRow] = []
        if filterDaily { rows.append(contentsOf: dailyLogs.map { .daily($0) }) }
        if filterWeekly { rows.append(contentsOf: weeklyLogs.map { .weekly($0) }) }
        if filterMaintenance { rows.append(contentsOf: maintenanceLogs.map { .maintenance($0) }) }
        if filterUsage { rows.append(contentsOf: usageLogs.map { .usage($0) }) }

        return rows.sorted { a, b in
            let ka = a.sortKey
            let kb = b.sortKey
            if ka.0 != kb.0 { return ka.0 > kb.0 }
            if ka.1 != kb.1 { return ka.1 > kb.1 }
            return a.createdAt > b.createdAt
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterChips

            if combinedRows.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(combinedRows) { row in
                        NavigationLink {
                            destination(for: row)
                        } label: {
                            HistoryRowView(row: row, isBromine: isBromine, palette: palette)
                        }
                        .listRowBackground(palette.color(.surfaceCard))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteTarget = row
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(palette.color(.backgroundSecondary))
        .navigationTitle("History")
        .onAppear { HotTubModelContainer.seedIfNeeded(in: modelContext) }
        .confirmationDialog("Delete this record?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let row = deleteTarget { delete(row) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Daily", on: $filterDaily)
                chip("Weekly", on: $filterWeekly)
                chip("Maintenance", on: $filterMaintenance)
                chip("Usage", on: $filterUsage)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func chip(_ title: String, on: Binding<Bool>) -> some View {
        Button {
            on.wrappedValue.toggle()
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(on.wrappedValue ? palette.color(.tagBlueFill) : palette.color(.surfaceCard))
                .foregroundStyle(on.wrappedValue ? palette.color(.accentBlue) : palette.color(.textSecondary))
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(palette.color(.separator), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(palette.color(.textTertiary))
            Text("No entries match these filters")
                .font(.subheadline)
                .foregroundStyle(palette.color(.textSecondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func destination(for row: HistoryRow) -> some View {
        switch row {
        case .daily(let l): DailyLogFormView(existing: l)
        case .weekly(let l): WeeklyLogFormView(existing: l)
        case .maintenance(let l): MaintenanceLogFormView(existing: l)
        case .usage(let l): UsageLogFormView(existing: l)
        }
    }

    private func delete(_ row: HistoryRow) {
        switch row {
        case .daily(let l): modelContext.delete(l)
        case .weekly(let l): modelContext.delete(l)
        case .maintenance(let l): modelContext.delete(l)
        case .usage(let l): modelContext.delete(l)
        }
        try? modelContext.save()
        deleteTarget = nil
    }
}

enum HistoryRow: Identifiable {
    case daily(HotTubDailyLog)
    case weekly(WeeklyCheckLog)
    case maintenance(MaintenanceLogEntry)
    case usage(UsageLogEntry)

    var id: String {
        switch self {
        case .daily(let x): "d-\(x.persistentModelID)"
        case .weekly(let x): "w-\(x.persistentModelID)"
        case .maintenance(let x): "m-\(x.persistentModelID)"
        case .usage(let x): "u-\(x.persistentModelID)"
        }
    }

    var sortKey: (String, String) {
        switch self {
        case .daily(let x): return (x.logDate, x.logTime)
        case .weekly(let x): return (x.logDate, x.logTime)
        case .maintenance(let x): return (x.logDate, x.logTime)
        case .usage(let x): return (x.usageDate, x.usageTime)
        }
    }

    var createdAt: Date {
        switch self {
        case .daily(let x): return x.createdAt
        case .weekly(let x): return x.createdAt
        case .maintenance(let x): return x.createdAt
        case .usage(let x): return x.createdAt
        }
    }

    var title: String {
        switch self {
        case .daily: return "Daily Log"
        case .weekly: return "Weekly Check"
        case .maintenance(let x): return x.action.isEmpty ? "Maintenance" : x.action
        case .usage: return "Hot Tub Usage"
        }
    }
}

private struct HistoryRowView: View {
    let row: HistoryRow
    let isBromine: Bool
    let palette: AppPalette

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.color(.textPrimary))
                HStack(spacing: 8) {
                    Text(formatDate(datePart))
                    if let t = timePart {
                        Text(t)
                    }
                }
                .font(.caption)
                .foregroundStyle(palette.color(.textSecondary))

                if case .daily(let log) = row {
                    HStack(spacing: 10) {
                        if let ph = log.ph {
                            Text("pH \(String(format: "%.1f", ph))")
                                .font(.caption2)
                                .foregroundStyle(phWarning(log) ? palette.color(.accentOrange) : palette.color(.textTertiary))
                        }
                        if let ppm = log.primarySanitizerPpm {
                            Text("\(isBromine ? "BR" : "FC") \(String(format: "%.1f", ppm))")
                                .font(.caption2)
                                .foregroundStyle(sanitizerWarning(log) ? palette.color(.accentOrange) : palette.color(.textTertiary))
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var icon: String {
        switch row {
        case .daily: return "drop.fill"
        case .weekly: return "checkmark.calendar"
        case .maintenance: return "wrench.fill"
        case .usage: return "timer"
        }
    }

    private var accent: Color {
        switch row {
        case .daily, .weekly: return palette.color(.accentBlue)
        case .maintenance: return palette.color(.accentOrange)
        case .usage: return palette.color(.accentGreen)
        }
    }

    private var datePart: String {
        switch row {
        case .daily(let x): return x.logDate
        case .weekly(let x): return x.logDate
        case .maintenance(let x): return x.logDate
        case .usage(let x): return x.usageDate
        }
    }

    private var timePart: String? {
        let raw: String
        switch row {
        case .daily(let x): raw = x.logTime
        case .weekly(let x): raw = x.logTime
        case .maintenance(let x): raw = x.logTime
        case .usage(let x): raw = x.usageTime
        }
        return String(raw.prefix(5))
    }

    private func formatDate(_ ymd: String) -> String {
        let fIn = DateFormatter()
        fIn.locale = Locale(identifier: "en_US_POSIX")
        fIn.dateFormat = "yyyy-MM-dd"
        guard let d = fIn.date(from: ymd) else { return ymd }
        let fOut = DateFormatter()
        fOut.dateFormat = "dd MMM yy"
        return fOut.string(from: d)
    }

    private func phWarning(_ log: HotTubDailyLog) -> Bool {
        guard let ph = log.ph else { return false }
        return ph < 7.2 || ph > 7.8
    }

    private func sanitizerWarning(_ log: HotTubDailyLog) -> Bool {
        guard let ppm = log.primarySanitizerPpm else { return false }
        if isBromine { return ppm < 3.0 || ppm > 5.0 }
        return ppm < 1.0 || ppm > 3.0
    }
}
