//
//  HistoryView.swift
//  HotTub Buddy
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette

    @Query(sort: \HotTubDailyLog.loggedAt, order: .reverse) private var dailyLogs: [HotTubDailyLog]
    @Query(sort: \WeeklyCheckLog.loggedAt, order: .reverse) private var weeklyLogs: [WeeklyCheckLog]
    @Query(sort: \MaintenanceLogEntry.loggedAt, order: .reverse) private var maintenanceLogs: [MaintenanceLogEntry]
    @Query(sort: \UsageLogEntry.loggedAt, order: .reverse) private var usageLogs: [UsageLogEntry]
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
            if a.sortMoment != b.sortMoment { return a.sortMoment > b.sortMoment }
            return a.createdAt > b.createdAt
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                filterChips

                if combinedRows.isEmpty {
                    AppEmptyState(
                        symbol: "tray",
                        title: "No entries",
                        message: "Try turning on more filters, or add a log from Activity on the dashboard."
                    )
                } else {
                    LazyVStack(spacing: AppSpacing.control) {
                        ForEach(combinedRows) { row in
                            historyRowLink(row)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.screenTop)
            .padding(.bottom, AppSpacing.screenBottom)
        }
        .appGroupedScreenBackground(palette)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
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
            HStack(spacing: AppSpacing.control) {
                AppFilterChip(title: "Daily", isOn: $filterDaily)
                AppFilterChip(title: "Weekly", isOn: $filterWeekly)
                AppFilterChip(title: "Maint.", isOn: $filterMaintenance)
                AppFilterChip(title: "Usage", isOn: $filterUsage)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
        .padding(.horizontal, -AppSpacing.screenHorizontal)
    }

    private func historyRowLink(_ row: HistoryRow) -> some View {
        NavigationLink {
            destination(for: row)
        } label: {
            HistoryRowView(row: row, isBromine: isBromine, palette: palette)
                .appCard(palette: palette, padding: 12)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteTarget = row
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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

    var sortMoment: Date {
        switch self {
        case .daily(let x): return x.loggedAt
        case .weekly(let x): return x.loggedAt
        case .maintenance(let x): return x.loggedAt
        case .usage(let x): return x.loggedAt
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
        case .daily: return "Daily log"
        case .weekly: return "Weekly check"
        case .maintenance(let x): return x.action.isEmpty ? "Maintenance" : x.action
        case .usage: return "Hot tub usage"
        }
    }
}

private struct HistoryRowView: View {
    let row: HistoryRow
    let isBromine: Bool
    let palette: AppPalette

    var body: some View {
        HStack(spacing: AppSpacing.control) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.color(.textPrimary))
                HStack(spacing: 8) {
                    Text(formatShortDate(row.sortMoment))
                    Text(timeString(row.sortMoment))
                }
                .font(.caption)
                .foregroundStyle(palette.color(.textPrimary).opacity(0.75))

                if case .daily(let log) = row {
                    HStack(spacing: 10) {
                        if let ph = log.ph {
                            Text("pH \(String(format: "%.1f", ph))")
                                .font(.caption)
                                .foregroundStyle(phWarning(log) ? palette.color(.accentOrange) : palette.color(.textSecondary))
                        }
                        if let ppm = log.primarySanitizerPpm {
                            Text("\(isBromine ? "BR" : "FC") \(String(format: "%.1f", ppm))")
                                .font(.caption)
                                .foregroundStyle(sanitizerWarning(log) ? palette.color(.accentOrange) : palette.color(.textSecondary))
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.color(.textTertiary))
        }
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

    private func formatShortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yy"
        return f.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
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
