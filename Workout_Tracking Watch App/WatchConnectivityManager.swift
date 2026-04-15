//
//  WatchConnectivityManager.swift
//  Workout_Tracking Watch App
//
//  Updated with workout mode support
//

import Foundation
import Combine
import WatchConnectivity

/// Workout-Feedback vom iPhone
struct WorkoutFeedback: Equatable {
    let repNumber: Int
    let classification: String
    let isCorrect: Bool
    let feedbackMessage: String
}

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isPhoneReachable: Bool = false
    @Published var receivedCommand: String = ""
    @Published var lastFeedback: WorkoutFeedback?
    @Published var currentMode: AppMode = .idle
    
    enum AppMode {
        case idle
        case dataCollection
        case workout
    }
    
    // Callbacks für verschiedene Modi
    var onStartTracking: (() -> Void)?
    var onStopTracking: (() -> Void)?
    var onStartWorkout: (() -> Void)?
    var onStopWorkout: (() -> Void)?
    
    private override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    // MARK: - Send Data to Phone
    
    /// Sendet Sensordaten für Data Collection (gesammelt, am Ende)
    func sendSensorData(_ data: [[String: Double]]) {
        guard WCSession.default.activationState == .activated else { return }
        
        let chunkSize = 200
        let chunks = stride(from: 0, to: data.count, by: chunkSize).map {
            Array(data[$0..<min($0 + chunkSize, data.count)])
        }
        
        print("Sending \(data.count) data points in \(chunks.count) chunks")
        
        for (index, chunk) in chunks.enumerated() {
            let message: [String: Any] = [
                "sensorData": chunk,
                "chunkIndex": index,
                "totalChunks": chunks.count
            ]
            WCSession.default.transferUserInfo(message)
        }
    }
    
    /// Sendet Sensordaten für Workout (live, für Inferenz)
    func sendWorkoutSensorData(_ data: [[String: Double]]) {
        guard WCSession.default.isReachable else { return }
        
        let message: [String: Any] = ["workoutSensorData": data]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending workout data: \(error.localizedDescription)")
        }
    }
    
    func sendStatus(_ status: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["status": status], replyHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
        }
    }
    
    // Receive commands from Phone
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            // Handle commands
            if let command = message["command"] as? String {
                self.receivedCommand = command
                print("Received command: \(command)")
                
                switch command {
                case "startTracking":
                    self.currentMode = .dataCollection
                    self.onStartTracking?()
                    replyHandler(["status": "tracking started"])
                    
                case "stopTracking":
                    self.currentMode = .idle
                    self.onStopTracking?()
                    replyHandler(["status": "tracking stopped"])
                    
                case "startWorkout":
                    self.currentMode = .workout
                    self.onStartWorkout?()
                    replyHandler(["status": "workout started"])
                    
                case "stopWorkout":
                    self.currentMode = .idle
                    self.onStopWorkout?()
                    replyHandler(["status": "workout stopped"])
                    
                default:
                    replyHandler(["status": "unknown command"])
                }
            }
            
            // Handle workout feedback
            if let type = message["type"] as? String, type == "workoutFeedback" {
                let feedback = WorkoutFeedback(
                    repNumber: message["repNumber"] as? Int ?? 0,
                    classification: message["classification"] as? String ?? "",
                    isCorrect: message["isCorrect"] as? Bool ?? false,
                    feedbackMessage: message["feedbackMessage"] as? String ?? ""
                )
                self.lastFeedback = feedback
            }
        }
    }
    
    // Handle messages without reply handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let type = message["type"] as? String, type == "workoutFeedback" {
                let feedback = WorkoutFeedback(
                    repNumber: message["repNumber"] as? Int ?? 0,
                    classification: message["classification"] as? String ?? "",
                    isCorrect: message["isCorrect"] as? Bool ?? false,
                    feedbackMessage: message["feedbackMessage"] as? String ?? ""
                )
                self.lastFeedback = feedback
            }
        }
    }
}
