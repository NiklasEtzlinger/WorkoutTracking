//
//  Workout_TrackingApp.swift
//  Workout_Tracking
//

import SwiftUI

@main
struct Workout_TrackingApp: App {
   @StateObject private var connectivityManager = PhoneConnectivityManager.shared
   var body: some Scene {
      WindowGroup {
         ContentView()
            .environmentObject(connectivityManager)
      }
   }
}
