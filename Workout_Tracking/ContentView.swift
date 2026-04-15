//
//  ContentView.swift
//  Workout_Tracking
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                // App Title
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Bicep Curl Tracker")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 20)
                
                // Main Buttons
                VStack(spacing: 20) {
                    NavigationLink(destination: WorkoutView()) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Start Workout")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Live Feedback mit ML")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 300, height: 80)
                        .background(
                            LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
                    }
                    
                    NavigationLink(destination: GetDataView()) {
                        HStack {
                            Image(systemName: "waveform.badge.plus")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Collect Data")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Trainingsdaten sammeln")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 300, height: 80)
                        .background(
                            LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .gray.opacity(0.3), radius: 5, y: 3)
                    }
                }
                
                Spacer()
                
                // Info Footer
                VStack(spacing: 4) {
                    Text("ML-Projekt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("FH Hagenberg")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
