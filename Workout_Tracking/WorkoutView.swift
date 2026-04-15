//
//  WorkoutView.swift
//  Workout_Tracking
//
//  Live workout view with rep counting and form feedback
//

import SwiftUI

struct WorkoutView: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var connectivityManager = PhoneConnectivityManager.shared
    
    @State private var isCountingDown: Bool = false
    @State private var countdown: Int = 5
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            // Connection Status
            HStack {
                Circle()
                    .fill(connectivityManager.isWatchReachable ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(connectivityManager.isWatchReachable ? "Watch verbunden" : "Watch nicht verbunden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if workoutManager.isWorkoutActive {
                // MARK: - Active Workout View
                activeWorkoutView
            } else if isCountingDown {
                // MARK: - Countdown View
                countdownView
            } else {
                // MARK: - Start View
                startView
            }
        }
        .padding()
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Start View
    private var startView: some View {
        VStack(spacing: 30) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("Bizeps Curl Tracker")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Das Modell analysiert deine Curls in Echtzeit und gibt dir Feedback zur Ausführung.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: startCountdown) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Workout starten")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 200, height: 50)
                .background(connectivityManager.isWatchReachable ? Color.green : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!connectivityManager.isWatchReachable)
        }
    }
    
    // MARK: - Countdown View
    private var countdownView: some View {
        VStack(spacing: 20) {
            Text("Mach dich bereit!")
                .font(.title2)
                .fontWeight(.semibold)
            
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.3), lineWidth: 10)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / 5.0)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: countdown)
                
                Text("\(countdown)")
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())
            }
            
            Text("Watch am Handgelenk bereit?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Active Workout View
    private var activeWorkoutView: some View {
        VStack(spacing: 20) {
            // Stats Header
            HStack(spacing: 30) {
                StatBox(title: "Reps", value: "\(workoutManager.stats.totalReps)", color: .blue)
                StatBox(title: "Korrekt", value: "\(workoutManager.stats.correctReps)", color: .green)
                StatBox(title: "Fehler", value: "\(workoutManager.stats.halfRomReps + workoutManager.stats.tooFastReps)", color: .red)
            }
            
            // Accuracy Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: workoutManager.stats.totalReps > 0 ? workoutManager.stats.correctPercentage / 100 : 0)
                    .stroke(
                        workoutManager.stats.correctPercentage >= 80 ? Color.green :
                        workoutManager.stats.correctPercentage >= 50 ? Color.orange : Color.red,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: workoutManager.stats.correctPercentage)
                
                VStack {
                    Text("\(Int(workoutManager.stats.correctPercentage))%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("Korrekt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Last Feedback
            feedbackBanner
            
            // Recent Reps
            if !workoutManager.repResults.isEmpty {
                recentRepsList
            }
            
            Spacer()
            
            // Stop Button
            Button(action: stopWorkout) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Workout beenden")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Feedback Banner
    private var feedbackBanner: some View {
        HStack {
            if let lastRep = workoutManager.repResults.last {
                Image(systemName: lastRep.isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(lastRep.isCorrect ? .green : (lastRep.classification == "half_rom" ? .orange : .red))
                
                Text(lastRep.feedbackMessage)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Rep \(lastRep.repNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text(workoutManager.lastFeedback)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut, value: workoutManager.repResults.count)
    }
    
    // MARK: - Recent Reps List
    private var recentRepsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Letzte Wiederholungen")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(workoutManager.repResults.suffix(10).reversed()) { rep in
                        RepBadge(rep: rep)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func startCountdown() {
        isCountingDown = true
        countdown = 5
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation {
                if countdown > 1 {
                    countdown -= 1
                } else {
                    timer?.invalidate()
                    timer = nil
                    isCountingDown = false
                    startWorkout()
                }
            }
        }
    }
    
    private func startWorkout() {
        workoutManager.startWorkout()
        connectivityManager.sendWorkoutStartCommand()
    }
    
    private func stopWorkout() {
        workoutManager.stopWorkout()
        connectivityManager.sendWorkoutStopCommand()
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 80)
    }
}

struct RepBadge: View {
    let rep: RepResult
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: rep.isCorrect ? "checkmark" : "xmark")
                .font(.caption)
                .fontWeight(.bold)
            Text("\(rep.repNumber)")
                .font(.caption2)
        }
        .frame(width: 36, height: 36)
        .background(
            rep.isCorrect ? Color.green.opacity(0.2) :
            rep.classification == "half_rom" ? Color.orange.opacity(0.2) : Color.red.opacity(0.2)
        )
        .foregroundStyle(
            rep.isCorrect ? .green :
            rep.classification == "half_rom" ? .orange : .red
        )
        .clipShape(Circle())
    }
}

#Preview {
    NavigationStack {
        WorkoutView()
    }
}
