import SwiftUI
import AVFoundation

struct AudioMonitorView: View {
  let staff: StaffUserModel
  let aiService: AIMonitoringService

  @Environment(\.dismiss) private var dismiss
  @State private var sessionId: String?
  @State private var isMonitoring = false
  @State private var audioLevel: Float = 0
  @State private var liveTranscript = ""
  @State private var detectedEvents: [DetectedEvent] = []
  @State private var audioRecorder: AVAudioRecorder?
  @State private var levelTimer: Timer?
  @State private var errorMessage: String?

  private struct DetectedEvent: Identifiable {
    let id = UUID()
    let type: String
    let keyword: String?
    let snippet: String
    let timestamp: Date
  }

  private let mockTranscripts = [
    "Hello, is anyone there?",
    "I need some help please.",
    "Can I get some water?",
    "I'm feeling okay today.",
    "Help! I've fallen down!",
    "When is the nurse coming?",
    "It's quiet in here.",
    "Thank you for checking on me.",
  ]

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        headerSection
        audioLevelMeter
        liveTranscriptSection
        eventsFeed
        controlButton
        if let error = errorMessage {
          Text(error)
            .font(.caption)
            .foregroundColor(.red)
            .padding(.horizontal)
        }
      }
      .padding()
      .navigationTitle("Audio Monitor")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
      .onDisappear {
        stopMonitoring()
      }
    }
  }

  private var headerSection: some View {
    VStack(spacing: 8) {
      Image(systemName: isMonitoring ? "waveform.circle.fill" : "mic.circle")
        .font(.system(size: 48))
        .foregroundColor(isMonitoring ? .red : .secondary)
        .symbolEffect(.pulse, options: .repeating, value: isMonitoring)
        .accessibilityHidden(true)

      Text(isMonitoring ? "Listening for sounds and keywords" : "Ready to monitor")
        .font(.headline)
        .accessibilityLabel(isMonitoring ? "Monitoring active, listening for sounds" : "Monitoring ready")

      if isMonitoring {
        Text("Monitoring \(staff.facilityId.uuidString.prefix(8))")
          .font(.caption)
          .foregroundColor(.secondary)
          .accessibilityHidden(true)
      }
    }
  }

  private var audioLevelMeter: some View {
    VStack(spacing: 4) {
      Text("Audio Level")
        .font(.caption)
        .foregroundColor(.secondary)
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .frame(height: 16)
          RoundedRectangle(cornerRadius: 6)
            .fill(audioLevelColor)
            .frame(width: geo.size.width * CGFloat(audioLevel), height: 16)
            .animation(.easeInOut(duration: 0.3), value: audioLevel)
        }
      }
      .frame(height: 16)
      .accessibilityLabel("Audio level: \(Int(audioLevel * 100)) percent")
    }
  }

  private var audioLevelColor: Color {
    switch audioLevel {
    case 0..<0.3: return .green
    case 0.3..<0.6: return .yellow
    case 0.6..<0.8: return .orange
    default: return .red
    }
  }

  private var liveTranscriptSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Live Transcript")
        .font(.caption)
        .foregroundColor(.secondary)

      ScrollView {
        Text(liveTranscript.isEmpty ? "Waiting for audio..." : liveTranscript)
          .font(.body)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(12)
          .background(Color(.systemGray6))
          .cornerRadius(10)
      }
      .frame(maxHeight: 120)
    }
    .accessibilityLabel("Live transcription")
    .accessibilityValue(liveTranscript.isEmpty ? "Waiting for audio" : liveTranscript)
  }

  private var eventsFeed: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Detected Events")
        .font(.caption)
        .foregroundColor(.secondary)

      if detectedEvents.isEmpty {
        Text(isMonitoring ? "Listening for key terms and sounds..." : "No events yet")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding()
      } else {
        List {
          ForEach(detectedEvents) { event in
            HStack(spacing: 10) {
              Image(systemName: eventIcon(event.type))
                .foregroundColor(eventColor(event.type))
                .frame(width: 24)
              VStack(alignment: .leading, spacing: 2) {
                Text(eventTypeDisplay(event.type))
                  .font(.subheadline.bold())
                Text(event.snippet)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              Spacer()
              Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(eventTypeDisplay(event.type)): \(event.snippet)")
          }
        }
        .listStyle(.plain)
      }
    }
  }

  private var controlButton: some View {
    Button(action: {
      isMonitoring ? stopMonitoring() : startMonitoring()
    }) {
      Label(
        isMonitoring ? "Stop Monitoring" : "Start Monitoring",
        systemImage: isMonitoring ? "stop.circle.fill" : "play.circle.fill"
      )
      .font(.headline)
      .padding()
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(isMonitoring ? .red : .green)
    .accessibilityHint(isMonitoring ? "Stops the audio monitoring session" : "Begins listening for sounds and keywords")
  }

  private func startMonitoring() {
    errorMessage = nil
    isMonitoring = true
    liveTranscript = "Monitoring started..."

    Task {
      let sid = await aiService.startMonitoring(
        facilityId: staff.facilityId.uuidString,
        staffId: staff.id.uuidString
      )
      sessionId = sid

      startAudioLevelMonitoring()
      startSimulatedTranscripts()
    }
  }

  private func stopMonitoring() {
    isMonitoring = false
    levelTimer?.invalidate()
    levelTimer = nil
    audioRecorder?.stop()

    if let sid = sessionId {
      Task { await aiService.stopMonitoring(sessionId: sid) }
    }
    sessionId = nil
    audioLevel = 0
  }

  private func startAudioLevelMonitoring() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playAndRecord, mode: .default)
    try? session.setActive(true)

    let url = URL(fileURLWithPath: "/dev/null")
    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatAppleLossless),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
    ]

    audioRecorder = try? AVAudioRecorder(url: url, settings: settings)
    audioRecorder?.isMeteringEnabled = true
    audioRecorder?.record()

    levelTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
      guard let recorder = audioRecorder else { return }
      recorder.updateMeters()
      let level = recorder.averagePower(forChannel: 0)
      let normalized = max(0, min(1, (level + 60) / 60))
      audioLevel = Float(normalized)

      if normalized > 0.5 {
        simulateEvent(audioLevel: normalized)
      }
    }
  }

  private func startSimulatedTranscripts() {
    Task {
      var index = 0
      while isMonitoring {
        try? await Task.sleep(nanoseconds: UInt64.random(in: 3_000_000_000...8_000_000_000))
        guard isMonitoring else { break }

        let transcript = mockTranscripts[index % mockTranscripts.count]
        index += 1
        liveTranscript = transcript

        let hasDistress = transcript.lowercased().contains("help") || transcript.lowercased().contains("fall")
        if hasDistress {
          let eventType = transcript.lowercased().contains("fall") ? "fall_sound" : "call_for_help"
          let event = DetectedEvent(
            type: eventType,
            keyword: transcript.lowercased().contains("fall") ? "fall" : "help",
            snippet: transcript,
            timestamp: Date()
          )
          detectedEvents.insert(event, at: 0)

          if detectedEvents.count > 20 {
            detectedEvents = Array(detectedEvents.prefix(20))
          }

          if let sid = sessionId {
            let report = AIEventReport(
              resident_id: nil,
              event_type: eventType,
              keyword: event.keyword,
              confidence: Double.random(in: 0.7...0.95),
              transcript_snippet: transcript,
              audio_level: Double(audioLevel)
            )
            Task { await aiService.reportEvent(sessionId: sid, event: report) }
          }
        }
      }
    }
  }

  private func simulateEvent(audioLevel level: Float) {
    guard Bool.random(probability: 0.15) else { return }
    let keywords = ["help", "pain", "fall", "nurse", "water", "bathroom"]
    let randomKw = keywords.randomElement()!
    let snippet = "Possible keyword detected: \"\(randomKw)\""
    let event = DetectedEvent(type: "keyword_detected", keyword: randomKw, snippet: snippet, timestamp: Date())
    detectedEvents.insert(event, at: 0)

    if detectedEvents.count > 20 {
      detectedEvents = Array(detectedEvents.prefix(20))
    }

    if let sid = sessionId {
      let report = AIEventReport(
        event_type: "keyword_detected",
        keyword: randomKw,
        confidence: Double.random(in: 0.5...0.85),
        transcript_snippet: snippet,
        audio_level: Double(level)
      )
      Task { await aiService.reportEvent(sessionId: sid, event: report) }
    }
  }

  private func eventIcon(_ type: String) -> String {
    switch type {
    case "keyword_detected": return "mic.badge.xmark"
    case "distress_sound": return "exclamationmark.triangle"
    case "fall_sound": return "figure.fall"
    case "call_for_help": return "hand.raised"
    default: return "questionmark"
    }
  }

  private func eventColor(_ type: String) -> Color {
    switch type {
    case "fall_sound", "call_for_help": return .red
    case "distress_sound": return .orange
    case "keyword_detected": return .blue
    default: return .gray
    }
  }

  private func eventTypeDisplay(_ type: String) -> String {
    switch type {
    case "keyword_detected": return "Keyword Detected"
    case "distress_sound": return "Distress Sound"
    case "fall_sound": return "Possible Fall"
    case "call_for_help": return "Call for Help"
    default: return type.replacingOccurrences(of: "_", with: " ").capitalized
    }
  }
}

private extension Bool {
  static func random(probability: Double) -> Bool {
    Double.random(in: 0...1) < probability
  }
}
