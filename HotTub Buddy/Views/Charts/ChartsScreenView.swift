//
//  ChartsScreenView.swift
//  HotTub Buddy
//

import Charts
import Combine
import SwiftData
import SwiftUI

private struct ChartPoint: Identifiable {
    let id: PersistentIdentifier
    let day: Date
    let value: Double
}

private struct UserBarPoint: Identifiable {
    let id: String
    let day: Date
    let count: Int
}

struct ChartsScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette

    @Query(sort: \HotTubDailyLog.logDate, order: .forward) private var allDaily: [HotTubDailyLog]
    @Query(sort: \UsageLogEntry.usageDate, order: .forward) private var allUsage: [UsageLogEntry]
    @Query private var settingsRows: [AppSettings]

    @State private var viewMonth: Date = Date()
    @State private var showSanitizer = true
    @State private var showPH = true
    @State private var showUsers = true

    private var isBromine: Bool {
        settingsRows.first?.isBromine ?? false
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: viewMonth)
    }

    private var monthBounds: (start: String, end: String) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: viewMonth)
        let start = cal.date(from: comps)!
        let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return (df.string(from: start), df.string(from: end))
    }

    private var logsInMonth: [HotTubDailyLog] {
        let b = monthBounds
        return allDaily.filter { $0.logDate >= b.start && $0.logDate <= b.end }
            .sorted { $0.logDate < $1.logDate || ($0.logDate == $1.logDate && $0.logTime < $1.logTime) }
    }

    private var usageInMonth: [UsageLogEntry] {
        let b = monthBounds
        return allUsage.filter { $0.usageDate >= b.start && $0.usageDate <= b.end }
    }

    private var userCountByDay: [String: Int] {
        var m: [String: Int] = [:]
        for u in usageInMonth {
            m[u.usageDate, default: 0] += u.numUsers
        }
        return m
    }

    private var hasData: Bool {
        !logsInMonth.isEmpty || !usageInMonth.isEmpty
    }

    private var chemicalOn: Bool {
        showSanitizer || showPH
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                monthNav
                toggles

                if !chemicalOn && !showUsers {
                    emptyCard("Turn on at least one chart layer.")
                } else if !hasData {
                    emptyCard("No daily logs or usage in \(monthLabel).")
                } else {
                    if showPH {
                        phChart
                    }
                    if showSanitizer {
                        sanitizerChart
                    }
                    if showUsers {
                        usersChart
                    }
                    guideSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(palette.color(.backgroundSecondary))
        .navigationTitle("Charts")
        .onAppear { HotTubModelContainer.seedIfNeeded(in: modelContext) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Analytics")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.color(.textSecondary))
            Text("Water quality trends")
                .font(.title.bold())
                .foregroundStyle(palette.color(.textPrimary))
        }
        .padding(.top, 8)
    }

    private var monthNav: some View {
        HStack {
            Button {
                viewMonth = Calendar.current.date(byAdding: .month, value: -1, to: viewMonth) ?? viewMonth
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(palette.color(.accentBlue))
            }
            Spacer()
            Text(monthLabel)
                .font(.headline)
            Spacer()
            Button {
                viewMonth = Calendar.current.date(byAdding: .month, value: 1, to: viewMonth) ?? viewMonth
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(palette.color(.accentBlue))
            }
        }
        .padding(.vertical, 8)
    }

    private var toggles: some View {
        HStack(spacing: 10) {
            togglePill(isBromine ? "BR" : "CL", on: $showSanitizer, color: palette.color(.accentBlue))
            togglePill("pH", on: $showPH, color: palette.color(.accentGreen))
            togglePill("Users", on: $showUsers, color: palette.color(.accentOrange))
        }
    }

    private func togglePill(_ title: String, on: Binding<Bool>, color: Color) -> some View {
        Button {
            on.wrappedValue.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: on.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(on.wrappedValue ? color : palette.color(.separator))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(palette.color(.surfaceCard))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(on.wrappedValue ? color : palette.color(.separator), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette.color(.textPrimary))
    }

    private var phChart: some View {
        let marks: [ChartPoint] = logsInMonth.compactMap { log in
            guard let ph = log.ph, let d = parseDate(log.logDate) else { return nil }
            return ChartPoint(id: log.persistentModelID, day: d, value: ph)
        }
        return chartCard(title: "pH") {
            if marks.isEmpty {
                Text("No pH readings this month")
                    .font(.caption)
                    .foregroundStyle(palette.color(.textSecondary))
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(marks) { mark in
                        LineMark(
                            x: .value("Day", mark.day),
                            y: .value("pH", mark.value)
                        )
                        .foregroundStyle(palette.color(.accentGreen))
                        PointMark(
                            x: .value("Day", mark.day),
                            y: .value("pH", mark.value)
                        )
                        .foregroundStyle(palette.color(.accentGreen))
                    }
                }
                .chartYScale(domain: 6.8 ... 8.2)
                .frame(height: 220)
            }
        }
    }

    private var sanitizerChart: some View {
        let marks: [ChartPoint] = logsInMonth.compactMap { log in
            guard let ppm = log.primarySanitizerPpm, let d = parseDate(log.logDate) else { return nil }
            return ChartPoint(id: log.persistentModelID, day: d, value: ppm)
        }
        let title = isBromine ? "Bromine (ppm)" : "Free chlorine (ppm)"
        return chartCard(title: title) {
            if marks.isEmpty {
                Text("No sanitizer readings this month")
                    .font(.caption)
                    .foregroundStyle(palette.color(.textSecondary))
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(marks) { mark in
                        LineMark(
                            x: .value("Day", mark.day),
                            y: .value("ppm", mark.value)
                        )
                        .foregroundStyle(palette.color(.accentBlue))
                        PointMark(
                            x: .value("Day", mark.day),
                            y: .value("ppm", mark.value)
                        )
                        .foregroundStyle(palette.color(.accentBlue))
                    }
                }
                .frame(height: 220)
            }
        }
    }

    private var usersChart: some View {
        let barPoints: [UserBarPoint] = userCountByDay.keys.sorted().compactMap { k in
            guard let d = parseDate(k), let n = userCountByDay[k] else { return nil }
            return UserBarPoint(id: k, day: d, count: n)
        }
        return chartCard(title: "Users per day") {
            if barPoints.isEmpty {
                Text("No usage logs this month")
                    .font(.caption)
                    .foregroundStyle(palette.color(.textSecondary))
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(barPoints) { p in
                        BarMark(
                            x: .value("Day", p.day),
                            y: .value("Users", p.count)
                        )
                        .foregroundStyle(palette.color(.accentOrange).opacity(0.85))
                    }
                }
                .frame(height: 220)
            }
        }
    }

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showSanitizer {
                guideBlock(
                    title: isBromine ? "Bromine" : "Chlorine",
                    text: isBromine
                        ? "Typical bromine 3.0–5.0 ppm. Add sanitizer when low; wait if high."
                        : "Typical free chlorine 1.0–3.0 ppm. Shock and circulation affect readings."
                )
            }
            if showPH {
                guideBlock(
                    title: "pH",
                    text: "Aim for 7.2–7.8. Affects comfort and sanitizer effectiveness."
                )
            }
        }
    }

    private func guideBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(text)
                .font(.caption)
                .foregroundStyle(palette.color(.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(palette.color(.surfaceCard))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(palette.color(.separator).opacity(0.6), lineWidth: 1)
        )
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(16)
        .background(palette.color(.surfaceCard))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(palette.color(.separator).opacity(0.6), lineWidth: 1)
        )
    }

    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(palette.color(.textSecondary))
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(palette.color(.surfaceCard))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func parseDate(_ ymd: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: ymd)
    }
}
