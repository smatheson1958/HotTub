//
//  MainTabView.swift
//  HotTub Buddy
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.appPalette) private var palette

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.split.2x1")
                }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "doc.text")
            }

            NavigationStack {
                ChartsScreenView()
            }
            .tabItem {
                Label("Charts", systemImage: "chart.bar")
            }

            NavigationStack {
                SetupView()
            }
            .tabItem {
                Label("Setup", systemImage: "gearshape")
            }
        }
        .tint(palette.color(.accentBlue))
    }
}
