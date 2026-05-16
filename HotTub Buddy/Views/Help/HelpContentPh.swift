//
//  HelpContentPh.swift
//  HotTub Buddy
//
//  Migrated from React `HelpModal/content/PhContent.jsx`.
//

import SwiftUI

struct HelpPhContent: View {
    @Environment(\.appPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("pH & Alkalinity Help Guide")
                .font(.title3.weight(.bold))
                .foregroundStyle(palette.color(.textPrimary))

            HelpCollapsibleSection(title: "pH – What it is", defaultExpanded: true) {
                HelpParagraph(text: "pH measures how acidic or alkaline the water is.", bold: true)
                HelpParagraph(text: "It affects comfort, sanitizer efficiency, and equipment life.", topPadding: 8)
                HelpIdealRange(label: "Ideal pH range", value: "7.2 – 7.6")
                HelpBullet(text: "Low pH = acidic")
                HelpBullet(text: "High pH = alkaline")
            }

            HelpCollapsibleSection(title: "pH Down (Lower pH)") {
                HelpParagraph(text: "Common scenarios", bold: true)
                HelpBullet(text: "pH is above 7.6")
                HelpBullet(text: "Water looks dull or cloudy")
                HelpBullet(text: "Scale forming")
                HelpBullet(text: "Chlorine/bromine not working efficiently")
                HelpParagraph(text: "Typical process (for reference)", bold: true, topPadding: 12)
                HelpBullet(text: "Commonly, users add a small dose of pH Down")
                HelpBullet(text: "Run circulation with air OFF")
                HelpBullet(text: "Wait 30–60 minutes")
                HelpBullet(text: "Retest and repeat if needed")
                HelpInfoBox {
                    Text(
                        "pH Down will also slightly lower alkalinity. Common practice is to lower pH gradually. Consult product labels for specific instructions."
                    )
                    .font(.subheadline)
                    .foregroundStyle(palette.color(.textSecondary))
                }
            }

            HelpCollapsibleSection(title: "pH Up (Raise pH)") {
                HelpParagraph(text: "Common scenarios", bold: true)
                HelpBullet(text: "pH is below 7.2")
                HelpBullet(text: "Water feels sharp or irritating")
                HelpBullet(text: "Corrosion risk to metal parts")
                HelpParagraph(text: "Typical process (for reference)", bold: true, topPadding: 12)
                HelpBullet(text: "Commonly, users add a small dose of pH Up")
                HelpBullet(text: "Circulate water for 20–30 minutes")
                HelpBullet(text: "Retest before adding more")
                HelpInfoBox {
                    Text(
                        "pH Up can also raise alkalinity. Consult product labels for specific guidance."
                    )
                    .font(.subheadline)
                    .foregroundStyle(palette.color(.textSecondary))
                }
            }

            HelpCollapsibleSection(title: "Total Alkalinity (TA) – What it is") {
                HelpParagraph(text: "Alkalinity buffers pH and helps prevent rapid pH swings.", bold: true)
                HelpIdealRange(label: "Ideal TA range", value: "80 – 120 ppm")
                HelpBullet(text: "Too high = pH keeps rising")
                HelpBullet(text: "Too low = pH unstable and hard to control")
            }

            HelpCollapsibleSection(title: "Alkalinity Up (Raise TA)") {
                HelpParagraph(text: "Common scenarios", bold: true)
                HelpBullet(text: "TA is below 80 ppm")
                HelpBullet(text: "pH swings up and down quickly")
                HelpBullet(text: "Water chemistry is unstable")
                HelpParagraph(text: "Typical process (for reference)", bold: true, topPadding: 12)
                HelpBullet(text: "Typically, users add Alkalinity Up in small stages")
                HelpBullet(text: "Circulate for 30 minutes")
                HelpBullet(text: "Retest TA before adding more")
                HelpInfoBox {
                    Text(
                        "Alkalinity Up raises pH as well. Common practice is to adjust alkalinity first, then pH. Always consult manufacturer guidelines."
                    )
                    .font(.subheadline)
                    .foregroundStyle(palette.color(.textSecondary))
                }
            }

            HelpCollapsibleSection(title: "Alkalinity Down (Lower TA)") {
                HelpParagraph(text: "Common scenarios", bold: true)
                HelpBullet(text: "TA is above 120–150 ppm")
                HelpBullet(text: "pH keeps drifting up despite adjustments")
                HelpParagraph(text: "General guidance (educational)", bold: true, topPadding: 12)
                HelpWarningBox {
                    Text("Alkalinity Down is typically NOT a common practice for direct use")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.color(.statusWarningText))
                }
                HelpParagraph(text: "Common approach:", topPadding: 8)
                HelpBullet(text: "Lower pH to ~7.2 using pH Down")
                HelpBullet(text: "Allow aeration/use to slowly bring pH back up")
                HelpBullet(text: "This process reduces TA naturally")
                HelpInfoBox {
                    Text(
                        "Direct TA reducers can overshoot and cause instability. Consult a spa professional for specific advice."
                    )
                    .font(.subheadline)
                    .foregroundStyle(palette.color(.textSecondary))
                }
            }

            HelpCollapsibleSection(title: "Common Adjustment Sequence (For Reference)") {
                HelpBullet(text: "1. Fix Alkalinity first (if outside range)")
                HelpBullet(text: "2. Then adjust pH")
                HelpBullet(text: "3. Make changes slowly and retest often")
            }

            HelpCollapsibleSection(title: "Common Mistakes to Avoid") {
                HelpBullet(text: "Chasing \"perfect\" numbers in one go")
                HelpBullet(text: "Adding pH Up and Down on the same day")
                HelpBullet(text: "Running air jets while lowering pH")
                HelpBullet(text: "Raising alkalinity when pH is already high")
            }

            HelpEducationalDisclaimer()
        }
    }
}
