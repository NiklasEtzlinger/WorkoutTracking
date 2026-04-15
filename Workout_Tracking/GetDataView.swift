//
//  GetDataView.swift
//  Workout_Tracking
//

import SwiftUI

enum ExerciseType: String, CaseIterable {
    case correct = "correct"
    case halfRom = "half_rom"
    case tooFast = "too_fast"
    
    var displayName: String {
        switch self {
        case .correct: return "✓ Korrekt"
        case .halfRom: return "✗ Half ROM"
        case .tooFast: return "✗ Too Fast"
        }
    }
}

struct GetDataView: View {
    @StateObject private var connectivityManager = PhoneConnectivityManager.shared
    @State private var isTracking: Bool = false
    @State private var isCountingDown: Bool = false
    @State private var countdown: Int = 5
    @State private var timer: Timer?
    @State private var showExportSheet: Bool = false
    @State private var exportURL: URL?
    
    // Metadaten
    @State private var personName: String = ""
    @State private var selectedType: ExerciseType = .correct
    @State private var sessionNumber: Int = 1
    
    var body: some View {
        VStack(spacing: 16) {
            // Status Anzeige
            HStack {
                Circle()
                    .fill(connectivityManager.isWatchReachable ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(connectivityManager.watchStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Metadaten Eingabe
            GroupBox("Session Info") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Person:")
                            .frame(width: 70, alignment: .leading)
                        TextField("Name", text: $personName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Text("Typ:")
                            .frame(width: 70, alignment: .leading)
                        Picker("", selection: $selectedType) {
                            ForEach(ExerciseType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    HStack {
                        Text("Session:")
                            .frame(width: 70, alignment: .leading)
                        Stepper("\(sessionNumber)", value: $sessionNumber, in: 1...99)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)
            
            // Hauptbutton
            Button(action: {
                if isTracking {
                    stopTracking()
                } else if !isCountingDown {
                    startCountdown()
                }
            }) {
                Circle()
                    .frame(width: 200, height: 200)
                    .foregroundStyle(buttonColor)
                    .overlay {
                        VStack {
                            if isCountingDown {
                                Text("\(countdown)")
                                    .font(.system(size: 60))
                                    .contentTransition(.numericText())
                            } else if isTracking {
                                Text("Stop")
                            } else {
                                Text("Start")
                            }
                        }
                        .font(.largeTitle)
                        .fontDesign(.monospaced)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    }
            }
            .disabled(isCountingDown || !connectivityManager.isWatchReachable || personName.isEmpty)
            
            // Hinweis wenn Name fehlt
            if personName.isEmpty {
                Text("Bitte Namen eingeben")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            // Daten Info
            Text("\(connectivityManager.receivedSensorData.count) Datenpunkte gesammelt")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            // Vorschau Dateiname
            if !personName.isEmpty && !connectivityManager.receivedSensorData.isEmpty {
                Text("→ \(generateFileName())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Export & Clear Buttons
            HStack(spacing: 20) {
                Button(action: {
                    if let url = connectivityManager.exportDataAsCSV(
                        person: personName,
                        type: selectedType.rawValue,
                        session: sessionNumber
                    ) {
                        exportURL = url
                        showExportSheet = true
                        sessionNumber += 1  // Auto-increment für nächste Session
                    }
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(connectivityManager.receivedSensorData.isEmpty || personName.isEmpty)
                
                Button(action: {
                    connectivityManager.clearData()
                }) {
                    Label("Clear", systemImage: "trash")
                        .font(.headline)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(connectivityManager.receivedSensorData.isEmpty)
            }
        }
        .padding()
        .navigationTitle("Collect Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
    }
    
    private func generateFileName() -> String {
        let cleanName = personName.lowercased().replacingOccurrences(of: " ", with: "_")
        return "\(cleanName)_\(selectedType.rawValue)_\(String(format: "%02d", sessionNumber)).csv"
    }
    
    private var buttonColor: Color {
        if !connectivityManager.isWatchReachable || personName.isEmpty {
            return .gray
        } else if isCountingDown {
            return .orange
        } else if isTracking {
            return .red
        } else {
            return .green
        }
    }
    
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
                    isTracking = true
                    connectivityManager.sendStartCommand()
                }
            }
        }
    }
    
    private func stopTracking() {
        isTracking = false
        connectivityManager.sendStopCommand()
    }
}

// Share Sheet für Export
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        GetDataView()
    }
}
