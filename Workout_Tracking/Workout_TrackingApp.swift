//
//  Workout_TrackingApp.swift
//  Workout_Tracking
//

import SwiftUI
import SwiftData

@main
struct Workout_TrackingApp: App {
   @StateObject private var connectivityManager = PhoneConnectivityManager.shared

   /// One shared SwiftData container for the whole app.
   let modelContainer: ModelContainer = {
      let schema = Schema([WorkoutSession.self, RepRecord.self])
      let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
      do {
         return try ModelContainer(for: schema, configurations: [config])
      } catch {
         fatalError("Failed to create ModelContainer: \(error)")
      }
   }()

   var body: some Scene {
      WindowGroup {
         ContentView()
            .environmentObject(connectivityManager)
            .tint(Theme.brand)
      }
      .modelContainer(modelContainer)
   }
}
