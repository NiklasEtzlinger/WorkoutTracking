//
//  ContentView.swift
//  Workout_Tracking Watch App
//
//  Updated with workout mode support and live feedback
//

import SwiftUI

struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Connection Status
            connectionStatusView
            
            // Content based on mode
            switch connectivityManager.currentMode {
            case .idle:
                idleView
            case .dataCollection:
                dataCollectionView
            case .workout:
                workoutView
            }
        }
        .padding()
        .onChange(of: connectivityManager.lastFeedback) { _, newFeedback in
            if let feedback = newFeedback {
                motionManager.updateFromFeedback(feedback)
            }
        }
    }
    
    // MARK: - Connection Status
    private var connectionStatusView: some View {
        HStack {
            Circle()
                .fill(connectivityManager.isPhoneReachable ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(connectivityManager.isPhoneReachable ? "Verbunden" : "Warte...")
                .font(.caption2)
        }
    }
    
    // MARK: - Idle View
    private var idleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text("Warte auf iPhone")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Starte 'Workout' oder\n'Collect Data' am iPhone")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Data Collection View
    private var dataCollectionView: some View {
        VStack(spacing: 10) {
            // Recording indicator
            Circle()
                .fill(motionManager.isRecording ? Color.red : Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay {
                    VStack(spacing: 2) {
                        Image(systemName: motionManager.isRecording ? "waveform" : "pause.fill")
                            .font(.title2)
                        if motionManager.isRecording {
                            Text("\(motionManager.dataPointCount)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.white)
                }
            
            Text(motionManager.isRecording ? "Aufnahme läuft..." : "Warte...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Workout View
    private var workoutView: some View {
        VStack(spacing: 8) {
            // Rep Count
            Text("\(motionManager.workoutRepCount)")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
            
            Text("Reps")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Feedback
            if !motionManager.lastFeedback.isEmpty {
                feedbackBadge
            }
            
            // Recording indicator
            if motionManager.isRecording {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Live")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Feedback Badge
    private var feedbackBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: motionManager.lastFeedbackIsCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.caption)
            
            Text(motionManager.lastFeedback)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            motionManager.lastFeedbackIsCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        )
        .foregroundStyle(
            motionManager.lastFeedbackIsCorrect ? .green : .red
        )
        .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
}
