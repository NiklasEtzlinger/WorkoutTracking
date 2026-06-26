//
//  ContentView.swift
//  Workout_Tracking
//
//  Root tab navigation. The live workout runs in a full-screen cover
//  presented over whichever tab is active.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var connectivity: PhoneConnectivityManager
    @State private var selectedTab: Tab = .home
    @State private var showWorkout = false

    enum Tab: Hashable {
        case home, history, insights, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                startWorkout: { showWorkout = true },
                showHistory: { selectedTab = .history }
            )
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
                .tag(Tab.insights)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .fullScreenCover(isPresented: $showWorkout) {
            WorkoutFlowView()
                .environmentObject(connectivity)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PhoneConnectivityManager.shared)
        .modelContainer(for: [WorkoutSession.self, RepRecord.self], inMemory: true)
}
