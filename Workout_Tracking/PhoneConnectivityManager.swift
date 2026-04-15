//
//  PhoneConnectivityManager.swift
//  Workout_Tracking
//
//  Updated with workout mode support
//

import Foundation
import Combine
import WatchConnectivity

class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()
    
    @Published var isWatchReachable: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var receivedSensorData: [[String: Double]] = []
    @Published var watchStatus: String = "Nicht verbunden"
    
    private override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else {
            watchStatus = "Watch nicht unterstützt"
            return
        }
        
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    // MARK: - Data Collection Commands
    
    func sendStartCommand() {
        sendCommand("startTracking")
    }
    
    func sendStopCommand() {
        sendCommand("stopTracking")
    }
    
    // MARK: - Workout Commands
    
    func sendWorkoutStartCommand() {
        sendCommand("startWorkout")
    }
    
    func sendWorkoutStopCommand() {
        sendCommand("stopWorkout")
    }
    
    func sendWorkoutFeedback(_ result: RepResult) {
        guard WCSession.default.isReachable else { return }
        
        let message: [String: Any] = [
            "type": "workoutFeedback",
            "repNumber": result.repNumber,
            "classification": result.classification,
            "confidence": result.confidence,
            "isCorrect": result.isCorrect,
            "feedbackMessage": result.feedbackMessage
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending feedback: \(error.localizedDescription)")
        }
    }
    
    private func sendCommand(_ command: String) {
        guard WCSession.default.isReachable else {
            watchStatus = "Watch nicht erreichbar"
            print("Watch not reachable")
            return
        }
        
        let message = ["command": command]
        WCSession.default.sendMessage(message, replyHandler: { response in
            print("Watch response: \(response)")
        }, errorHandler: { error in
            print("Error sending command: \(error.localizedDescription)")
        })
        
        print("Sent command: \(command)")
    }
    
    // MARK: - Data Export (for Data Collection mode)
    
    func exportDataAsCSV(person: String, type: String, session: Int) -> URL? {
        guard !receivedSensorData.isEmpty else { return nil }
        
        let headers = "timestamp,accX,accY,accZ,rotX,rotY,rotZ,pitch,roll,yaw\n"
        var csvString = headers
        
        for dataPoint in receivedSensorData {
            let timestamp = String(dataPoint["timestamp"] ?? 0)
            let accX = String(dataPoint["accX"] ?? 0)
            let accY = String(dataPoint["accY"] ?? 0)
            let accZ = String(dataPoint["accZ"] ?? 0)
            let rotX = String(dataPoint["rotX"] ?? 0)
            let rotY = String(dataPoint["rotY"] ?? 0)
            let rotZ = String(dataPoint["rotZ"] ?? 0)
            let pitch = String(dataPoint["pitch"] ?? 0)
            let roll = String(dataPoint["roll"] ?? 0)
            let yaw = String(dataPoint["yaw"] ?? 0)
            
            let row = [timestamp, accX, accY, accZ, rotX, rotY, rotZ, pitch, roll, yaw]
                .joined(separator: ",")
            
            csvString += row + "\n"
        }
        
        let cleanName = person.lowercased().replacingOccurrences(of: " ", with: "_")
        let fileName = "\(cleanName)_\(type)_\(String(format: "%02d", session)).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
    
    func clearData() {
        receivedSensorData.removeAll()
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            switch activationState {
            case .activated:
                self.watchStatus = "Verbunden"
                self.isWatchAppInstalled = session.isWatchAppInstalled
                self.isWatchReachable = session.isReachable
            case .inactive:
                self.watchStatus = "Inaktiv"
            case .notActivated:
                self.watchStatus = "Nicht aktiviert"
            @unknown default:
                self.watchStatus = "Unbekannt"
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.watchStatus = "Inaktiv"
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            self.watchStatus = session.isReachable ? "Verbunden" : "Nicht erreichbar"
        }
    }
    
    // Receive messages from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let status = message["status"] as? String {
                print("Watch status: \(status)")
            }
            
            // Sensor data for data collection
            if let sensorData = message["sensorData"] as? [[String: Double]] {
                self.receivedSensorData.append(contentsOf: sensorData)
                print("Received \(sensorData.count) data points. Total: \(self.receivedSensorData.count)")
            }
            
            // Workout sensor data - process immediately
            if let workoutData = message["workoutSensorData"] as? [[String: Double]] {
                WorkoutManager.shared.processSensorData(workoutData)
            }
        }
    }
    
    // Receive userInfo (background transfer)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            if let sensorData = userInfo["sensorData"] as? [[String: Double]] {
                self.receivedSensorData.append(contentsOf: sensorData)
                print("Received (background) \(sensorData.count) data points")
            }
        }
    }
}
