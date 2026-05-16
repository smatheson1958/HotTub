//
//  AppUI.swift
//  HotTub Buddy
//
//  Shared layout primitives (Documents/ui + AppPalette).
//

import SwiftUI

enum AppSpacing {
    static let screenHorizontal: CGFloat = 20
    static let screenTop: CGFloat = 16
    static let screenBottom: CGFloat = 32
    static let section: CGFloat = 24
    static let stack: CGFloat = 16
    static let control: CGFloat = 12
    static let cardRadius: CGFloat = 16
    static let largeCardRadius: CGFloat = 20
    static let minTap: CGFloat = 44
}

// MARK: - Background

extension View {
    func appGroupedScreenBackground(_ palette: AppPalette) -> some View {
        background(palette.color(.backgroundSecondary).ignoresSafeArea())
    }

    func appCard(
        palette: AppPalette,
        radius: CGFloat = AppSpacing.cardRadius,
        padding: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(palette.color(.surfaceCard))
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(palette.color(.separator).opacity(0.35), lineWidth: 1)
            }
    }
}

// MARK: - Section header

struct AppSectionHeader: View {
    let title: String
    var subtitle: String?

    @Environment(\.appPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(palette.color(.textPrimary))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.color(.textSecondary))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Empty state

struct AppEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    @Environment(\.appPalette) private var palette

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(palette.color(.textTertiary))
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.color(.textPrimary))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(palette.color(.textSecondary))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .appCard(palette: palette)
    }
}

// MARK: - Filter chip

struct AppFilterChip: View {
    let title: String
    @Binding var isOn: Bool

    @Environment(\.appPalette) private var palette

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                isOn.toggle()
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .frame(minHeight: AppSpacing.minTap)
                .background(isOn ? palette.color(.tagBlueFill) : palette.color(.surfaceCard))
                .foregroundStyle(isOn ? palette.color(.accentBlue) : palette.color(.textSecondary))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isOn ? palette.color(.accentBlue).opacity(0.4) : palette.color(.separator).opacity(0.5),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings rows (card interior)

struct AppSettingsDivider: View {
    @Environment(\.appPalette) private var palette

    var body: some View {
        Divider()
            .overlay(palette.color(.separator).opacity(0.5))
            .padding(.leading, 16)
    }
}

struct AppSettingsLabeledRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    @Environment(\.appPalette) private var palette

    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.body)
                .foregroundStyle(palette.color(.textPrimary))
            Spacer(minLength: 16)
            content
        }
        .padding(.horizontal, 16)
        .frame(minHeight: AppSpacing.minTap)
    }
}

struct AppSettingsValueRow: View {
    let label: String
    let value: String

    @Environment(\.appPalette) private var palette

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(palette.color(.textPrimary))
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(palette.color(.textSecondary))
        }
        .padding(.horizontal, 16)
        .frame(minHeight: AppSpacing.minTap)
    }
}

// MARK: - Primary button

struct AppPrimaryButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.appPalette) private var palette

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(palette.color(.accentBlue))
        .controlSize(.large)
    }
}
