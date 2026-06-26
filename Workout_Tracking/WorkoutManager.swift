//
//  WorkoutManager.swift
//  Workout_Tracking
//
//  Manages CoreML inference and rep detection during workouts
//

import Foundation
import CoreML
import Combine

/// Result of a single rep classification.
struct RepResult: Identifiable {
    let id = UUID()
    let repNumber: Int
    let classification: String      // raw: "correct" / "half_rom" / "too_fast" / "unknown"
    let confidence: Double
    let timestamp: Date

    var type: RepClassification { RepClassification(raw: classification) }
    var isCorrect: Bool { type.isCorrect }
    var feedbackMessage: String { type.feedback }
}

/// Workout-Statistiken
struct WorkoutStats {
    var totalReps: Int = 0
    var correctReps: Int = 0
    var halfRomReps: Int = 0
    var tooFastReps: Int = 0
    
    var correctPercentage: Double {
        guard totalReps > 0 else { return 0 }
        return Double(correctReps) / Double(totalReps) * 100
    }
}

/// Status der Rep-Erkennung
enum RepPhase {
    case idle           // Warten auf Bewegung
    case curlUp         // Aufwärtsbewegung erkannt
    case curlDown       // Abwärtsbewegung erkannt
}

class WorkoutManager: ObservableObject {
    static let shared = WorkoutManager()
    
    // MARK: - Published Properties
    @Published var isWorkoutActive: Bool = false
    @Published var currentExercise: Exercise = .bicepCurl
    @Published var repResults: [RepResult] = []
    @Published var stats = WorkoutStats()
    @Published var lastFeedback: String = ""
    @Published var currentRepData: [[String: Double]] = []
    @Published var debugInfo: String = ""  // For debugging

    /// Wall-clock bounds of the current/last workout (used when saving).
    private(set) var startDate: Date = Date()
    private(set) var endDate: Date?
    
    // MARK: - Private Properties
    private var model: BicepCurlClassifier?
    private var sensorBuffer: [[String: Double]] = []
    private let sampleRate: Double = 50.0
    
    // Rep Detection State
    private var repPhase: RepPhase = .idle
    private var repStartIndex: Int = 0
    private var peakRotY: Double = 0
    private var minRoll: Double = .infinity
    private var maxRoll: Double = -.infinity
    
    // MARK: - Thresholds (WICHTIG: Diese Werte anpassen!)
    private let minRotYThreshold: Double = 1.0      // Minimum rotY für Bewegungserkennung
    private let minRollRange: Double = 0.8          // Minimum Roll-Änderung (in Radians, ~45°)
    private let minRepDuration: Double = 0.8        // Minimum Rep-Dauer in Sekunden
    private let maxRepDuration: Double = 4.0        // Maximum Rep-Dauer in Sekunden
   private let cooldownDuration: Double = 0.3       // Cooldown in Sekunden

   private var lastRepTime: Date = .distantPast    // Zeitpunkt des letzten Reps
    
    // MARK: - Initialization
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly
            model = try BicepCurlClassifier(configuration: config)
            print("CoreML Model loaded successfully")
        } catch {
            print("Failed to load CoreML model: \(error)")
        }
    }
    
    // MARK: - Workout Control
    func startWorkout(exercise: Exercise = .bicepCurl) {
        currentExercise = exercise
        startDate = Date()
        endDate = nil
        isWorkoutActive = true
        repResults.removeAll()
        stats = WorkoutStats()
        sensorBuffer.removeAll()
        currentRepData.removeAll()
        lastFeedback = exercise.supportsFormGrading
            ? "Let's go — give me clean reps!"
            : "Let's go — counting your reps!"
        resetRepDetection()

        print("Workout started: \(exercise.displayName)")
    }

    func stopWorkout() {
        isWorkoutActive = false
        endDate = Date()
        lastFeedback = "Workout complete"
        print("Workout stopped. Total reps: \(stats.totalReps)")
    }

    /// Seconds elapsed for the finished workout.
    var elapsedSeconds: Double {
        (endDate ?? Date()).timeIntervalSince(startDate)
    }

    /// Mean model confidence across all classified reps (0–1).
    var averageConfidence: Double {
        guard !repResults.isEmpty else { return 0 }
        return repResults.map(\.confidence).reduce(0, +) / Double(repResults.count)
    }
    
    private func resetRepDetection() {
        repPhase = .idle
        repStartIndex = 0
        peakRotY = 0
        minRoll = .infinity
        maxRoll = -.infinity
    }
    
    // MARK: - Sensor Data Processing
    func processSensorData(_ data: [[String: Double]]) {
        guard isWorkoutActive else { return }
        
        sensorBuffer.append(contentsOf: data)
        
        // Rep-Detection mit verbessertem Algorithmus
        detectRepsImproved()
        
        // Buffer begrenzen (behalte letzte 15 Sekunden)
        let maxBufferSize = Int(sampleRate * 15)
        if sensorBuffer.count > maxBufferSize {
            let removeCount = sensorBuffer.count - maxBufferSize
            sensorBuffer.removeFirst(removeCount)
            repStartIndex = max(0, repStartIndex - removeCount)
        }
    }
    
   // MARK: - Improved Rep Detection
   private func detectRepsImproved() {
       guard sensorBuffer.count > 10 else { return }
       
       // Cooldown basierend auf Zeit, nicht Samples
       if Date().timeIntervalSince(lastRepTime) < cooldownDuration {
           return
       }
       
       // Analysiere die neuesten Datenpunkte
       let startIdx = max(0, sensorBuffer.count - 10)
       
       for i in startIdx..<sensorBuffer.count {
           guard let rotY = sensorBuffer[i]["rotY"],
                 let roll = sensorBuffer[i]["roll"] else { continue }
           
           // Update min/max Roll für aktuellen Rep
           minRoll = min(minRoll, roll)
           maxRoll = max(maxRoll, roll)
           
           // Update peak rotY
           if abs(rotY) > abs(peakRotY) {
               peakRotY = rotY
           }
           
           // State Machine für Rep-Detection
           switch repPhase {
           case .idle:
               // Warte auf signifikante Aufwärtsbewegung (positive rotY)
               if rotY > minRotYThreshold {
                   repPhase = .curlUp
                   repStartIndex = i
                   peakRotY = rotY
                   minRoll = roll
                   maxRoll = roll
                   debugInfo = "⬆️ Curl Up detected"
               }
               
           case .curlUp:
               // Warte auf Richtungswechsel (negative rotY = Abwärtsbewegung)
               if rotY < -minRotYThreshold {
                   repPhase = .curlDown
                   debugInfo = "⬇️ Curl Down detected"
               }
               // Timeout: Wenn zu lange in curlUp, reset
               else if i - repStartIndex > Int(maxRepDuration * sampleRate) {
                   resetRepDetection()
                   debugInfo = "⏱️ Timeout in curlUp"
               }
               
           case .curlDown:
               // Warte bis Bewegung stoppt (rotY nahe 0) oder wieder positiv wird
               if rotY > -0.3 && rotY < 0.3 {
                   // Rep abgeschlossen - validieren
                   validateAndClassifyRep(endIndex: i)
               }
               // Oder wenn wieder Aufwärtsbewegung beginnt
               else if rotY > minRotYThreshold * 0.5 {
                   validateAndClassifyRep(endIndex: i)
               }
               // Timeout
               else if i - repStartIndex > Int(maxRepDuration * sampleRate) {
                   validateAndClassifyRep(endIndex: i)
               }
           }
       }
       
       // Update debug info
       DispatchQueue.main.async {
           if let lastRotY = self.sensorBuffer.last?["rotY"],
              let lastRoll = self.sensorBuffer.last?["roll"] {
               let rollRange = self.maxRoll - self.minRoll
               self.debugInfo = String(format: "rotY: %.2f | Roll: %.0f° | \(self.repPhase)",
                                       lastRotY, rollRange * 57.3)
           }
       }
   }
    
   private func validateAndClassifyRep(endIndex: Int) {
       let repEndIndex = min(endIndex, sensorBuffer.count)
       guard repStartIndex < repEndIndex else {
           resetRepDetection()
           return
       }
       
       let repData = Array(sensorBuffer[repStartIndex..<repEndIndex])
       
       // Validierung 1: Genug Datenpunkte?
       let minSamples = Int(minRepDuration * sampleRate)
       guard repData.count >= minSamples else {
           debugInfo = "❌ Zu kurz: \(repData.count) samples"
           resetRepDetection()
           return
       }
       
       // Validierung 2: Roll Range groß genug?
       let rollRange = maxRoll - minRoll
       guard rollRange >= minRollRange else {
           debugInfo = String(format: "❌ Roll zu klein: %.0f°", rollRange * 57.3)
           resetRepDetection()
           return
       }
       
       // Validierung 3: Peak rotY groß genug?
       guard abs(peakRotY) >= minRotYThreshold else {
           debugInfo = String(format: "❌ Peak rotY zu klein: %.2f", peakRotY)
           resetRepDetection()
           return
       }
       
       // Rep ist valide! Klassifizieren
       debugInfo = String(format: "✅ Rep! Roll: %.0f°, Peak: %.2f", rollRange * 57.3, peakRotY)
       classifyRep(repData)
       
       // Reset für nächsten Rep
       resetRepDetection()
       lastRepTime = Date()  // Cooldown startet jetzt
   }
    
    // MARK: - Classification

    /// Exercises that don't support form grading are simply counted.
    private func countRepOnly() {
        DispatchQueue.main.async {
            self.stats.totalReps += 1
            let result = RepResult(
                repNumber: self.stats.totalReps,
                classification: RepClassification.unknown.rawValue,
                confidence: 1.0,
                timestamp: Date()
            )
            self.repResults.append(result)
            self.lastFeedback = "Rep \(self.stats.totalReps)"
            PhoneConnectivityManager.shared.sendWorkoutFeedback(result)
        }
    }

    private func classifyRep(_ repData: [[String: Double]]) {
        // Push-ups (and any future count-only exercise) skip the curl model.
        guard currentExercise.supportsFormGrading else {
            countRepOnly()
            return
        }

        guard let model = model else {
            print("Model not loaded")
            return
        }
        
        // Features extrahieren
        let features = extractFeatures(from: repData)
        
        do {
            // CoreML Inference
            let input = try createModelInput(features: features)
            let prediction = try model.prediction(input: input)
            
            let classification = prediction.classLabel
            let probability = prediction.classProbability[classification] ?? 0.0
            
            // Ergebnis speichern
            DispatchQueue.main.async {
                self.stats.totalReps += 1
                
                switch classification {
                case "correct":
                    self.stats.correctReps += 1
                case "half_rom":
                    self.stats.halfRomReps += 1
                case "too_fast":
                    self.stats.tooFastReps += 1
                default:
                    break
                }
                
                let result = RepResult(
                    repNumber: self.stats.totalReps,
                    classification: classification,
                    confidence: probability,
                    timestamp: Date()
                )
                
                self.repResults.append(result)
                self.lastFeedback = result.feedbackMessage
                
                // Sende Feedback zur Watch
                PhoneConnectivityManager.shared.sendWorkoutFeedback(result)
                
                print("Rep \(self.stats.totalReps): \(classification) (\(Int(probability * 100))%)")
            }
            
        } catch {
            print("Classification error: \(error)")
        }
    }
    
    // MARK: - Feature Extraction
    private func extractFeatures(from repData: [[String: Double]]) -> [Double] {
        var features: [Double] = []
        
        let sensorColumns = ["accX", "accY", "accZ", "rotX", "rotY", "rotZ", "pitch", "roll", "yaw"]
        
        for col in sensorColumns {
            let values = repData.compactMap { $0[col] }
            features.append(contentsOf: extractStatisticalFeatures(from: values))
        }
        
        // Zusätzliche Features
        features.append(contentsOf: extractAdditionalFeatures(from: repData))
        
        return features
    }
    
    private func extractStatisticalFeatures(from values: [Double]) -> [Double] {
        guard !values.isEmpty else {
            return Array(repeating: 0.0, count: 10)
        }
        
        let sorted = values.sorted()
        let n = Double(values.count)
        
        let mean = values.reduce(0, +) / n
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / n
        let std = sqrt(variance)
        let minVal = sorted.first ?? 0
        let maxVal = sorted.last ?? 0
        let range = maxVal - minVal
        let median = sorted[values.count / 2]
        let q25 = sorted[values.count / 4]
        let q75 = sorted[(values.count * 3) / 4]
        let iqr = q75 - q25
        let rms = sqrt(values.map { $0 * $0 }.reduce(0, +) / n)
        
        return [mean, std, minVal, maxVal, range, median, q25, q75, iqr, rms]
    }
    
    private func extractAdditionalFeatures(from repData: [[String: Double]]) -> [Double] {
        // Duration
        let duration: Double
        if let firstTs = repData.first?["timestamp"], let lastTs = repData.last?["timestamp"] {
            duration = lastTs - firstTs
        } else {
            duration = Double(repData.count) / sampleRate
        }
        
        // Peak rotY
        let rotYValues = repData.compactMap { $0["rotY"] }
        let peakRotY = rotYValues.map { abs($0) }.max() ?? 0
        
        // Roll Range
        let rollValues = repData.compactMap { $0["roll"] }
        let rollRange = (rollValues.max() ?? 0) - (rollValues.min() ?? 0)
        
        // Zero Crossings in rotY
        var zeroCrossings = 0
        for i in 1..<rotYValues.count {
            if rotYValues[i-1] * rotYValues[i] < 0 {
                zeroCrossings += 1
            }
        }
        
        // Total Energy
        var energy: Double = 0
        for col in ["accX", "accY", "accZ"] {
            let values = repData.compactMap { $0[col] }
            energy += values.map { $0 * $0 }.reduce(0, +)
        }
        let totalEnergy = sqrt(energy / max(Double(repData.count), 1))
        
        return [duration, peakRotY, rollRange, Double(zeroCrossings), totalEnergy]
    }
    
    // MARK: - CoreML Input Creation
    private func createModelInput(features: [Double]) throws -> BicepCurlClassifierInput {
        guard features.count == 95 else {
            throw NSError(domain: "WorkoutManager", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Feature count mismatch: expected 95, got \(features.count)"])
        }
        
        return BicepCurlClassifierInput(
            accX_mean: features[0],
            accX_std: features[1],
            accX_min: features[2],
            accX_max: features[3],
            accX_range: features[4],
            accX_median: features[5],
            accX_q25: features[6],
            accX_q75: features[7],
            accX_iqr: features[8],
            accX_rms: features[9],
            accY_mean: features[10],
            accY_std: features[11],
            accY_min: features[12],
            accY_max: features[13],
            accY_range: features[14],
            accY_median: features[15],
            accY_q25: features[16],
            accY_q75: features[17],
            accY_iqr: features[18],
            accY_rms: features[19],
            accZ_mean: features[20],
            accZ_std: features[21],
            accZ_min: features[22],
            accZ_max: features[23],
            accZ_range: features[24],
            accZ_median: features[25],
            accZ_q25: features[26],
            accZ_q75: features[27],
            accZ_iqr: features[28],
            accZ_rms: features[29],
            rotX_mean: features[30],
            rotX_std: features[31],
            rotX_min: features[32],
            rotX_max: features[33],
            rotX_range: features[34],
            rotX_median: features[35],
            rotX_q25: features[36],
            rotX_q75: features[37],
            rotX_iqr: features[38],
            rotX_rms: features[39],
            rotY_mean: features[40],
            rotY_std: features[41],
            rotY_min: features[42],
            rotY_max: features[43],
            rotY_range: features[44],
            rotY_median: features[45],
            rotY_q25: features[46],
            rotY_q75: features[47],
            rotY_iqr: features[48],
            rotY_rms: features[49],
            rotZ_mean: features[50],
            rotZ_std: features[51],
            rotZ_min: features[52],
            rotZ_max: features[53],
            rotZ_range: features[54],
            rotZ_median: features[55],
            rotZ_q25: features[56],
            rotZ_q75: features[57],
            rotZ_iqr: features[58],
            rotZ_rms: features[59],
            pitch_mean: features[60],
            pitch_std: features[61],
            pitch_min: features[62],
            pitch_max: features[63],
            pitch_range: features[64],
            pitch_median: features[65],
            pitch_q25: features[66],
            pitch_q75: features[67],
            pitch_iqr: features[68],
            pitch_rms: features[69],
            roll_mean: features[70],
            roll_std: features[71],
            roll_min: features[72],
            roll_max: features[73],
            roll_range: features[74],
            roll_median: features[75],
            roll_q25: features[76],
            roll_q75: features[77],
            roll_iqr: features[78],
            roll_rms: features[79],
            yaw_mean: features[80],
            yaw_std: features[81],
            yaw_min: features[82],
            yaw_max: features[83],
            yaw_range: features[84],
            yaw_median: features[85],
            yaw_q25: features[86],
            yaw_q75: features[87],
            yaw_iqr: features[88],
            yaw_rms: features[89],
            duration: features[90],
            peak_rotY: features[91],
            peak_roll_range: features[92],
            zero_crossings_rotY: features[93],
            energy_total: features[94]
        )
    }
}
