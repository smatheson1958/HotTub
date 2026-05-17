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
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                statusCard
                quickActions
                recentActivity
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.screenTop)
            .padding(.bottom, AppSpacing.screenBottom)
        }
        .appGroupedScreenBackground(palette)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .task { viewModel.reload(context: modelContext) }
        .onAppear { viewModel.reload(context: modelContext) }
        .refreshable { viewModel.reload(context: modelContext) }
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
                    log.map { "Last checked: \(formatShortDate($0.loggedAt))" } ?? "No records yet"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.color(.onAccent))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }

            Text(hasData ? "Latest readings" : "Your hot tub")
                .font(.body)
                .foregroundStyle(palette.color(.onAccent).opacity(0.85))

            Text(
                log.map {
                    viewModel.statusSummary(ph: $0.ph, sanitizer: $0.primarySanitizerPpm)
                } ?? "Ready to start?"
            )
            .font(.system(size: 28, weight: .heavy))
            .foregroundStyle(palette.color(.onAccent))

            if hasData {
                Text(
                    "Typical ranges are for reference only. Test your water and follow product labels before adding chemicals."
                )
                .font(.caption)
                .foregroundStyle(palette.color(.onAccent).opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
            }

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
        .padding(20)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.largeCardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private func sanitizerDisplay(_ log: HotTubDailyLog?) -> String {
        guard let ppm = log?.primarySanitizerPpm else { return "-- ppm" }
        return String(format: "%.1f ppm", ppm)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.control) {
            AppSectionHeader(title: "Quick actions")

            HStack(spacing: AppSpacing.control) {
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
        .appCard(palette: palette, radius: AppSpacing.largeCardRadius)
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: AppSpacing.control) {
            HStack(alignment: .firstTextBaseline) {
                AppSectionHeader(title: "Recent activity")
                Spacer()
                NavigationLink("See all") {
                    HistoryView()
                }
                .font(.subheadline.weight(.medium))
            }

            if viewModel.recentActivity.isEmpty {
                AppEmptyState(
                    symbol: "clock.arrow.circlepath",
                    title: "No activity yet",
                    message: "Log a daily reading or usage session to see it here."
                )
            } else {
                ForEach(viewModel.recentActivity) { item in
                    activityRow(item)
                }
            }
        }
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
                        Label(formatShortDate(moment(for: item)), systemImage: "calendar")
                        Label(timeHM(moment(for: item)), systemImage: "clock")
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
            .appCard(palette: palette, padding: 12)
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

    private func moment(for item: DashboardActivity) -> Date {
        switch item {
        case .daily(let x): return x.loggedAt
        case .weekly(let x): return x.loggedAt
        case .maintenance(let x): return x.loggedAt
        case .usage(let x): return x.loggedAt
        }
    }

    private func formatShortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yy"
        return f.string(from: date)
    }

    private func timeHM(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

}
