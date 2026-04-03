//
//  Placeholders.swift
//  HotTub
//

import SwiftUI

struct ActivityHubView: View {
    @Environment(\.appPalette) private var palette

    var body: some View {
        List {
            Section {
                NavigationLink {
                    DailyLogFormView()
                } label: {
                    Label("Daily log", systemImage: "drop.fill")
                }
                NavigationLink {
                    WeeklyLogFormView()
                } label: {
                    Label("Weekly check", systemImage: "checkmark.calendar")
                }
                NavigationLink {
                    MaintenanceLogFormView()
                } label: {
                    Label("Maintenance", systemImage: "wrench.fill")
                }
                NavigationLink {
                    UsageLogFormView()
                } label: {
                    Label("Usage", systemImage: "timer")
                }
            } header: {
                Text("New entry")
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.color(.backgroundSecondary))
        .navigationTitle("Activity")
    }
}
