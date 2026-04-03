//
//  DashboardView.swift
//  HotTub Buddy
//

import Combine
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    statusCard
                    consumptionSection
                    quickActions
                    recentActivity
                }
                .padding(.bottom, 28)
            }
            .background(palette.color(.backgroundSecondary).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { viewModel.reload(context: modelContext) }
        .onAppear { viewModel.reload(context: modelContext) }
        .refreshable { viewModel.reload(context: modelContext) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.color(.textSecondary))
            Text("Hot Tub Monitor")
                .font(.title.bold())
                .foregroundStyle(palette.color(.textPrimary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var statusCard: some View {
        let log = viewModel.latestDailyLog
        let hasData = log != nil
        let gradient = LinearGradient(
            colors: hasData
                ? [palette.color(.accentBlue), palette.color(.accentIndigo).opacity(0.92)]
                : [palette.color(.heroEmptyStart), palette.color(.heroEmptyEnd)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(palette.color(.onAccent))
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Spacer()
                Text(
                    log.map { "Last checked: \(formatShortDate($0.logDate))" } ?? "No records yet"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.color(.onAccent))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }

            Text("Current Status")
                .font(.body)
                .foregroundStyle(palette.color(.onAccent).opacity(0.85))

            Text(
                log.map {
                    viewModel.statusText(ph: $0.ph, sanitizer: $0.primarySanitizerPpm)
                } ?? "Ready to start?"
            )
            .font(.system(size: 28, weight: .heavy))
            .foregroundStyle(palette.color(.onAccent))

            HStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isBromine ? "Bromine" : "Chlorine")
                        .font(.caption)
                        .foregroundStyle(palette.color(.onAccent).opacity(0.65))
                    HStack(spacing: 6) {
                        Text(sanitizerDisplay(log))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(palette.color(.onAccent))
                        if let log, viewModel.sanitizerOutOfRange(log.primarySanitizerPpm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(palette.color(.accentYellow))
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("pH Level")
                        .font(.caption)
                        .foregroundStyle(palette.color(.onAccent).opacity(0.65))
                    HStack(spacing: 6) {
                        Text(log?.ph.map { String(format: "%.1f", $0) } ?? "--")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(palette.color(.onAccent))
                        if let log, viewModel.phOutOfRange(log.ph) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(palette.color(.accentYellow))
                        }
                    }
                }
            }
        }
        .padding(22)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private func sanitizerDisplay(_ log: HotTubDailyLog?) -> String {
        guard let ppm = log?.primarySanitizerPpm else { return "-- ppm" }
        return String(format: "%.1f ppm", ppm)
    }

    @ViewBuilder
    private var consumptionSection: some View {
        if let rate = viewModel.currentRate,
           viewModel.dataConfidence?.confidence != "insufficient"
        {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(palette.color(.accentOrange))
                        .padding(8)
                        .background(palette.color(.accentOrange).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text("Sanitizer Consumption")
                        .font(.headline)
                        .foregroundStyle(palette.color(.textPrimary))
                }

                if let msg = viewModel.dataConfidence?.warningMessage {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.color(.accentOrange))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Limited Data Available")
                                .font(.subheadline.weight(.semibold))
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(palette.color(.textSecondary))
                        }
                    }
                    .padding(12)
                    .background(palette.color(.statusWarningFill))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(palette.color(.statusWarningBorder), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(spacing: 6) {
                    Text("\(formatGrams(rate.gramsPerDay)) \(viewModel.weightUnit)/day")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(palette.color(.textPrimary))
                    Text("\(formatGrams(rate.ppmPerDay)) ppm/day • Last \(formatDays(rate.daysElapsed))")
                        .font(.subheadline)
                        .foregroundStyle(palette.color(.textSecondary))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                if let avg = viewModel.averageRate {
                    Divider()
                        .background(palette.color(.separator))
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("7-day average")
                                .font(.caption)
                                .foregroundStyle(palette.color(.textTertiary))
                            Text("\(formatGrams(avg.avgGramsPerDay)) \(viewModel.weightUnit)/day")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(palette.color(.textPrimary))
                        }
                        Spacer()
                        if let pct = viewModel.trendPercent, let up = viewModel.trendUp {
                            HStack(spacing: 4) {
                                Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                                Text("\(Int(pct))%")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(up ? palette.color(.accentRed) : palette.color(.accentGreen))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                (up ? palette.color(.accentRed) : palette.color(.accentGreen)).opacity(0.12)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }
            .padding(18)
            .background(palette.color(.surfaceCard))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(palette.color(.separator).opacity(0.6), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(palette.color(.textPrimary))

            HStack(spacing: 12) {
                NavigationLink {
                    ActivityHubView()
                } label: {
                    quickActionTile(
                        title: "Activity",
                        systemImage: "list.clipboard",
                        fillToken: .tagBlueFill,
                        iconToken: .accentBlue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ChartsScreenView()
                } label: {
                    quickActionTile(
                        title: "Charts",
                        systemImage: "chart.bar.fill",
                        fillToken: .tagGreenFill,
                        iconToken: .accentGreen
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private func quickActionTile(
        title: String,
        systemImage: String,
        fillToken: PaletteToken,
        iconToken: PaletteToken
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(palette.color(iconToken))
                .padding(10)
                .background(palette.color(fillToken))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.color(.textPrimary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(palette.color(.surfaceCard))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(palette.color(.separator).opacity(0.6), lineWidth: 1)
        )
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundStyle(palette.color(.textPrimary))
                Spacer()
                NavigationLink("See All") {
                    HistoryView()
                }
                .font(.subheadline.weight(.medium))
                .tint(palette.color(.accentBlue))
            }

            if viewModel.recentActivity.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundStyle(palette.color(.textSecondary))
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(palette.color(.surfaceCard))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(palette.color(.separator).opacity(0.6), lineWidth: 1)
                    )
            } else {
                ForEach(viewModel.recentActivity) { item in
                    activityRow(item)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func activityRow(_ item: DashboardActivity) -> some View {
        NavigationLink {
            activityDetail(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconName(item))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.color(item.accentToken))
                    .frame(width: 40, height: 40)
                    .background(palette.color(item.accentToken).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.color(.textPrimary))
                    HStack(spacing: 12) {
                        Label(formatShortDate(dateString(item)), systemImage: "calendar")
                        if let t = timeString(item), !t.isEmpty {
                            Label(t, systemImage: "clock")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(palette.color(.textSecondary))
                    .labelStyle(.titleAndIcon)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.color(.textTertiary))
            }
            .padding(12)
            .background(palette.color(.surfaceCard))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(palette.color(.separator).opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.delete(item, context: modelContext)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func activityDetail(_ item: DashboardActivity) -> some View {
        switch item {
        case .daily(let log):
            DailyLogFormView(existing: log)
        case .weekly(let log):
            WeeklyLogFormView(existing: log)
        case .maintenance(let log):
            MaintenanceLogFormView(existing: log)
        case .usage(let log):
            UsageLogFormView(existing: log)
        }
    }

    private func iconName(_ item: DashboardActivity) -> String {
        switch item {
        case .daily: return "drop.fill"
        case .weekly: return "checkmark.calendar"
        case .maintenance: return "wrench.fill"
        case .usage: return "timer"
        }
    }

    private func dateString(_ item: DashboardActivity) -> String {
        switch item {
        case .daily(let x): return x.logDate
        case .weekly(let x): return x.logDate
        case .maintenance(let x): return x.logDate
        case .usage(let x): return x.usageDate
        }
    }

    private func timeString(_ item: DashboardActivity) -> String? {
        switch item {
        case .daily(let x): return String(x.logTime.prefix(5))
        case .weekly(let x): return String(x.logTime.prefix(5))
        case .maintenance(let x): return String(x.logTime.prefix(5))
        case .usage(let x): return String(x.usageTime.prefix(5))
        }
    }

    private func formatShortDate(_ ymd: String) -> String {
        let fIn = DateFormatter()
        fIn.locale = Locale(identifier: "en_US_POSIX")
        fIn.dateFormat = "yyyy-MM-dd"
        guard let d = fIn.date(from: ymd) else { return ymd }
        let fOut = DateFormatter()
        fOut.dateFormat = "dd MMM yy"
        return fOut.string(from: d)
    }

    private func formatGrams(_ v: Double) -> String {
        String(format: "%.2f", v)
    }

    private func formatDays(_ v: Double) -> String {
        v == floor(v) ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
