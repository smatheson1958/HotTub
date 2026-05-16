//
//  SetupDisclaimerView.swift
//  HotTub
//

import SwiftUI

struct SetupDisclaimerView: View {
    @Environment(\.appPalette) private var palette
    @AppStorage(DisclaimerAcceptance.storageKey) private var acceptedDisclaimerVersion = ""
    @State private var showFullDisclaimer = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stack) {
            header
            introParagraph
            sectionsCard
            warningBanner
            viewFullDisclaimerButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .sheet(isPresented: $showFullDisclaimer) {
            DisclaimerSheetView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    palette.color(.statusWarningText),
                    palette.color(.accentYellow)
                )

            Text("Important Disclaimer")
                .font(.title2.bold())
                .foregroundStyle(palette.color(.textPrimary))

            Text(versionLine)
                .font(.subheadline)
                .foregroundStyle(palette.color(.textSecondary))
        }
    }

    private var versionLine: String {
        if DisclaimerAcceptance.isAccepted(acceptedDisclaimerVersion) {
            "Accepted version \(DisclaimerAcceptance.currentVersion) • Last updated \(DisclaimerAcceptance.lastUpdated)"
        } else {
            "Version \(DisclaimerAcceptance.currentVersion) • Last updated \(DisclaimerAcceptance.lastUpdated)"
        }
    }

    private var introParagraph: some View {
        (
            Text("This is a ")
            + Text("free, non-commercial informational app").bold()
            + Text(
                " provided by Curley Brackets Engineering Ltd for tracking and reference purposes only. It does not provide professional advice and does not replace manufacturer instructions or professional services."
            )
        )
        .font(.subheadline)
        .foregroundStyle(palette.color(.textPrimary))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var sectionsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.stack) {
            disclaimerSection(title: "Water Chemistry") {
                (
                    Text("This app is a ")
                    + Text("logging and tracking tool").bold()
                    + Text(" for recording your hot tub maintenance. Any water chemistry values, ranges, or guidance shown are ")
                    + Text("for reference only").bold()
                    + Text(
                        ". The app does not calculate or recommend chemical dosages. Always follow your hot tub or spa manufacturer's guidance and the instructions on chemical products. Users are responsible for "
                    )
                    + Text("testing their own water").bold()
                    + Text(" and making their own decisions about chemical treatment.")
                )
            }

            disclaimerSection(title: "Safety") {
                Text(
                    "Pool and spa chemicals can be hazardous if handled incorrectly. Always read and follow product labels, safety warnings, and safety data sheets."
                )
            }

            disclaimerSection(title: "Local Laws") {
                (
                    Text(
                        "Laws, standards, and recommended practices may vary by country or region. Users are responsible for ensuring compliance with "
                    )
                    + Text("local regulations").bold()
                    + Text(" and manufacturer guidance.")
                )
            }

            disclaimerSection(title: "No Warranty / Limitation of Liability") {
                (
                    Text("This app is provided ")
                    + Text("\"as is\"").bold()
                    + Text(", without warranties of any kind. To the fullest extent permitted by applicable law, Curley Brackets Engineering Ltd accepts ")
                    + Text("no liability for loss, damage, or injury").bold()
                    + Text(" arising from use of this app. Use of the app is entirely ")
                    + Text("at the user's own risk").bold()
                    + Text(".")
                )
            }
        }
        .appCard(palette: palette, radius: AppSpacing.cardRadius)
    }

    private var warningBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(palette.color(.statusWarningText))

            Text("Always test your water before adding chemicals and never exceed manufacturer dosing guidelines.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.color(.statusWarningText))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.color(.statusWarningFill))
        .overlay {
            RoundedRectangle(cornerRadius: AppSpacing.cardRadius, style: .continuous)
                .strokeBorder(palette.color(.statusWarningBorder), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardRadius, style: .continuous))
    }

    private var viewFullDisclaimerButton: some View {
        Button {
            showFullDisclaimer = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.body.weight(.semibold))
                Text("View Full Disclaimer")
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette.color(.textPrimary))
        .background(palette.color(.surfaceCard))
        .overlay {
            RoundedRectangle(cornerRadius: AppSpacing.cardRadius, style: .continuous)
                .strokeBorder(palette.color(.separator).opacity(0.5), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardRadius, style: .continuous))
    }

    private func disclaimerSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.color(.textPrimary))

            content()
                .font(.subheadline)
                .foregroundStyle(palette.color(.textPrimary))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ScrollView {
        SetupDisclaimerView()
            .padding()
    }
    .appPalette(.light)
}
