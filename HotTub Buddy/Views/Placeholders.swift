//
//  Placeholders.swift
//  HotTub Buddy
//

import SwiftUI

struct ActivityHubView: View {
    @Environment(\.appPalette) private var palette

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.control),
        GridItem(.flexible(), spacing: AppSpacing.control),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppSectionHeader(
                    title: "New entry",
                    subtitle: "Choose what you want to log"
                )

                LazyVGrid(columns: columns, spacing: AppSpacing.control) {
                    ForEach(ActivityEntry.allCases) { entry in
                        NavigationLink {
                            entry.destination
                        } label: {
                            entryTile(
                                title: entry.title,
                                systemImage: entry.systemImage,
                                fillToken: entry.fillToken,
                                iconToken: entry.iconToken
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.screenTop)
            .padding(.bottom, AppSpacing.screenBottom)
        }
        .appGroupedScreenBackground(palette)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
    }

    private func entryTile(
        title: String,
        systemImage: String,
        fillToken: PaletteToken,
        iconToken: PaletteToken
    ) -> some View {
        VStack(spacing: AppSpacing.control) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(palette.color(iconToken))
                .frame(width: AppSpacing.minTap, height: AppSpacing.minTap)
                .background(palette.color(fillToken))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.color(.textPrimary))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .appCard(palette: palette, radius: AppSpacing.largeCardRadius)
    }
}

private enum ActivityEntry: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case maintenance
    case usage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "Daily log"
        case .weekly: "Weekly check"
        case .maintenance: "Maintenance"
        case .usage: "Usage"
        }
    }

    var systemImage: String {
        switch self {
        case .daily: "drop.fill"
        case .weekly: "checkmark.calendar"
        case .maintenance: "wrench.fill"
        case .usage: "timer"
        }
    }

    var fillToken: PaletteToken {
        switch self {
        case .daily: .tagBlueFill
        case .weekly: .tagGreenFill
        case .maintenance: .tagOrangeFill
        case .usage: .tagPinkFill
        }
    }

    var iconToken: PaletteToken {
        switch self {
        case .daily: .accentBlue
        case .weekly: .accentGreen
        case .maintenance: .accentOrange
        case .usage: .accentPink
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .daily:
            DailyLogFormView()
        case .weekly:
            WeeklyLogFormView()
        case .maintenance:
            MaintenanceLogFormView()
        case .usage:
            UsageLogFormView()
        }
    }
}
