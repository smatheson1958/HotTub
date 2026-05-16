//
//  HelpContentSanitizer.swift
//  HotTub Buddy
//
//  Migrated from React `HelpModal/content/SanitizerContent.jsx`.
//

import SwiftUI

struct HelpSanitizerContent: View {
    let isBromine: Bool
    @Environment(\.appPalette) private var palette

    private var name: String { isBromine ? "Bromine" : "Chlorine" }
    private var nameLower: String { isBromine ? "bromine" : "chlorine" }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(name) & Copper – Help Guide")
                .font(.title3.weight(.bold))
                .foregroundStyle(palette.color(.textPrimary))

            HelpCollapsibleSection(title: "\(name) – What it does", defaultExpanded: true) {
                HelpParagraph(
                    text: "\(name) is the primary sanitizer that kills bacteria, viruses, and algae in hot tubs.",
                    bold: true
                )
            }

            HelpCollapsibleSection(title: "Free \(name) (FC)", defaultExpanded: true) {
                HelpParagraph(text: "What it is", bold: true)
                HelpParagraph(text: "\(name) available to sanitize", topPadding: 4)
                HelpParagraph(text: "The most important \(nameLower) value", topPadding: 4)
                HelpIdealRange(
                    label: "Ideal range",
                    value: isBromine ? "3–5 ppm" : "1–3 ppm (free), 3–5 ppm (total)"
                )
                HelpParagraph(text: "If too low", bold: true, topPadding: 12)
                HelpBullet(text: "Poor sanitation")
                HelpBullet(text: "Risk of bacteria growth")
                HelpBullet(text: "Cloudy or smelly water")
                HelpParagraph(text: "If too high", bold: true, topPadding: 12)
                HelpBullet(text: "Skin and eye irritation")
                HelpBullet(text: "Strong \(nameLower) smell")
                HelpBullet(text: "Faster wear on covers and plastics")
            }

            if !isBromine {
                HelpCollapsibleSection(title: "Combined Chlorine (CC)") {
                    HelpParagraph(text: "What it is", bold: true)
                    HelpParagraph(text: "Chlorine that has reacted with contaminants", topPadding: 4)
                    HelpParagraph(text: "Also called chloramines", topPadding: 4)
                    HelpIdealRange(label: "Ideal range", value: "0–0.5 ppm")
                    HelpParagraph(text: "Signs of high CC", bold: true, topPadding: 12)
                    HelpBullet(text: "\"Chlorine\" smell (not actually free chlorine)")
                    HelpBullet(text: "Eye irritation")
                    HelpBullet(text: "Water smells musty or unpleasant")
                    HelpParagraph(text: "Typical approach to address high CC", bold: true, topPadding: 12)
                    HelpBullet(text: "Commonly, users shock the spa (raise chlorine to 8–10 ppm briefly)")
                    HelpBullet(text: "Leave cover open during shocking")
                }
            }

            HelpCollapsibleSection(title: "Total \(name) (TC)") {
                HelpParagraph(text: "What it is", bold: true)
                HelpParagraph(
                    text: isBromine
                        ? "Total bromine in the water (active + used)"
                        : "Free Chlorine + Combined Chlorine",
                    topPadding: 4
                )
                if !isBromine {
                    HelpInfoBox {
                        Text("Key relationship:\nCombined Chlorine = Total Chlorine − Free Chlorine")
                            .font(.subheadline)
                            .foregroundStyle(palette.color(.textSecondary))
                    }
                    HelpParagraph(text: "Example", bold: true, topPadding: 12)
                    HelpBullet(text: "Total Chlorine = 4.4 ppm")
                    HelpBullet(text: "Free Chlorine = 4.3 ppm")
                    HelpBullet(text: "Combined Chlorine = 0.1 ppm ✓")
                }
            }

            HelpCollapsibleSection(title: "\(name) & pH – Important Link") {
                HelpBullet(text: "High pH makes \(nameLower) less effective")
                HelpBullet(text: "Best \(nameLower) performance is at pH 7.2–7.6")
                HelpBullet(text: "If \(nameLower) \"won't hold,\" always check pH first")
            }

            HelpCollapsibleSection(title: "Copper (Cu) – What it is") {
                HelpParagraph(text: "Why copper appears in hot tubs", bold: true)
                HelpBullet(text: "From copper heat exchangers")
                HelpBullet(text: "Metal components")
                HelpBullet(text: "Some algaecides or mineral systems")
                HelpBullet(text: "Corrosion caused by low pH")
                HelpIdealRange(label: "Ideal Copper Level", value: "0.0 – 0.2 ppm")
                HelpWarningBox {
                    Text("Anything above 0.3 ppm can cause problems")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.color(.statusWarningText))
                }
                HelpParagraph(text: "Problems caused by high copper", bold: true, topPadding: 12)
                HelpBullet(text: "Green or blue water")
                HelpBullet(text: "Staining on shells, jets, and fittings")
                HelpBullet(text: "Green hair or nail staining")
                HelpBullet(text: "Discoloured plastic components")
            }

            HelpCollapsibleSection(title: "Copper & pH – Critical Link") {
                HelpWarningBox {
                    Text("Low pH dissolves copper into the water")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.color(.statusWarningText))
                }
                HelpBullet(text: "Acidic water dramatically increases copper release")
                HelpBullet(text: "Keeping pH stable prevents copper staining")
            }

            HelpCollapsibleSection(title: "Copper & \(name) – Important Interaction") {
                HelpWarningBox {
                    Text("High \(nameLower) + metals = oxidised staining")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.color(.statusWarningText))
                }
                HelpParagraph(text: "Shocking water with copper present can:", topPadding: 8)
                HelpBullet(text: "Lock stains into surfaces")
                HelpBullet(text: "Cause sudden colour changes")
            }

            HelpCollapsibleSection(title: "General Management Guidance for Copper") {
                HelpBullet(text: "Keep pH 7.2–7.6")
                HelpBullet(text: "Avoid unnecessary metal-based products")
                HelpBullet(text: "Use a metal sequestrant if copper is detected")
                HelpBullet(text: "Avoid shocking if copper is already high (treat metals first)")
            }

            HelpCollapsibleSection(title: "Common Mistakes to Avoid") {
                HelpBullet(text: "Ignoring pH when \(nameLower) won't hold")
                HelpBullet(text: "Shocking water with known metal contamination")
                HelpBullet(text: "Using copper-based algaecides in hot tubs")
                HelpBullet(text: "Letting pH drop below 7.0")
            }

            HelpEducationalDisclaimer()
        }
    }
}
