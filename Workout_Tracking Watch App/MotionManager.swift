//
//  MotionManager.swift
//  Workout_Tracking Watch App
//
//  Updated with workout mode support
//

import Foundation
import Combine
import CoreMotion
import WatchKit

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let connectivityManager = WatchConnectivityManager.shared
    
    @Published var isRecording: Bool = false
    @Published var dataPointCount: Int = 0
    @Published var currentMode: WatchConnectivityManager.AppMode = .idle
    
    // Workout stats (mirrored from iPhone)
    @Published var workoutRepCount: Int = 0
    @Published var lastFeedback: String = ""
    @Published var lastFeedbackIsCorrect: Bool = true
    
    private var sensorData: [[String: Double]] = []
    private var workoutBuffer: [[String: Double]] = []
    private let sampleRate: Double = 50.0
    private var sendTimer: Timer?
    
    init() {
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        // Data Collection callbacks
        connectivityManager.onStartTracking = { [weak self] in
            self?.startRecording(mode: .dataCollection)
        }
        connectivityManager.onStopTracking = { [weak self] in
            self?.stopRecording()
        }
        
        // Workout callbacks
        connectivityManager.onStartWorkout = { [weak self] in
            self?.startRecording(mode: .workout)
        }
        connectivityManager.onStopWorkout = { [weak self] in
            self?.stopRecording()
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording(mode: WatchConnectivityManager.AppMode) {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        currentMode = mode
        sensorData.removeAll()
        workoutBuffer.removeAll()
        dataPointCount = 0
        workoutRepCount = 0
        lastFeedback = mode == .workout ? "Los geht's!" : ""
        
        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRate
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else {
                if let error = error {
                    print("Motion error: \(error.localizedDescription)")
                }
                return
            }
            
            let dataPoint: [String: Double] = [
                "timestamp": Date().timeIntervalSince1970,
                "accX": motion.userAcceleration.x,
                "accY": motion.userAcceleration.y,
                "accZ": motion.userAcceleration.z,
                "rotX": motion.rotationRate.x,
                "rotY": motion.rotationRate.y,
                "rotZ": motion.rotationRate.z,
                "pitch": motion.attitude.pitch,
                "roll": motion.attitude.roll,
                "yaw": motion.attitude.yaw
            ]
            
            if self.currentMode == .dataCollection {
                self.sensorData.append(dataPoint)
                self.dataPointCount = self.sensorData.count
            } else if self.currentMode == .workout {
                self.workoutBuffer.append(dataPoint)
                self.dataPointCount = self.workoutBuffer.count
            }
        }
        
        isRecording = true
        
        // Im Workout-Modus: Sende Daten regelmäßig ans iPhone
        if mode == .workout {
            startWorkoutDataSending()
        }
        
        // Haptic Feedback
        WKInterfaceDevice.current().play(.start)
        
        connectivityManager.sendStatus("Recording started (\(mode))")
        print("Started recording at \(sampleRate) Hz - Mode: \(mode)")
    }
    
    func stopRecording() {
        motionManager.stopDeviceMotionUpdates()
        sendTimer?.invalidate()
        sendTimer = nil
        isRecording = false
        
        // Data Collection: Sende alle Daten am Ende
        if currentMode == .dataCollection && !sensorData.isEmpty {
            connectivityManager.sendSensorData(sensorData)
            connectivityManager.sendStatus("Recording stopped. Sent \(sensorData.count) points.")
        }
        
        // Workout: Letzte Daten senden
        if currentMode == .workout && !workoutBuffer.isEmpty {
            connectivityManager.sendWorkoutSensorData(workoutBuffer)
        }
        
        // Haptic Feedback
        WKInterfaceDevice.current().play(.stop)
        
        currentMode = .idle
        print("Stopped recording. Collected \(max(sensorData.count, workoutBuffer.count)) data points")
    }
    
    // MARK: - Workout Data Streaming
    
    private func startWorkoutDataSending() {
        // Sende alle 0.5 Sekunden Daten ans iPhone für Live-Inferenz
        sendTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if !self.workoutBuffer.isEmpty {
                self.connectivityManager.sendWorkoutSensorData(self.workoutBuffer)
                // Buffer leeren nach Senden
                self.workoutBuffer.removeAll()
            }
        }
    }
    
    // MARK: - Feedback Updates
    
    func updateFromFeedback(_ feedback: WorkoutFeedback) {
        workoutRepCount = feedback.repNumber
        lastFeedback = feedback.feedbackMessage
        lastFeedbackIsCorrect = feedback.isCorrect
        
        // Haptic Feedback basierend auf Ergebnis
        if feedback.isCorrect {
            WKInterfaceDevice.current().play(.success)
        } else {
            WKInterfaceDevice.current().play(.failure)
        }
    }
}
