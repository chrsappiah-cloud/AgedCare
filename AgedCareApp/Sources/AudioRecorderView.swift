import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
  let onSave: (URL) -> Void
  @Environment(\.dismiss) private var dismiss

  @State private var isRecording = false
  @State private var recordedURL: URL?
  @State private var audioPlayer: AVAudioPlayer?
  @State private var isPlaying = false
  @State private var recordingDuration: TimeInterval = 0
  @State private var timer: Timer?

  private let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

  var body: some View {
    VStack(spacing: 24) {
      Text(isRecording ? "Recording..." : recordedURL != nil ? "Recording saved" : "Tap to record")
        .font(.headline)

      ZStack {
        Circle()
          .fill(isRecording ? Color.red : Color(.secondarySystemBackground))
          .frame(width: 80, height: 80)

        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
          .font(.title)
          .foregroundColor(.white)
      }
      .onTapGesture {
        if isRecording {
          stopRecording()
        } else {
          startRecording()
        }
      }

      if let url = recordedURL {
        HStack(spacing: 16) {
          Button(action: playAudio) {
            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
              .font(.title2)
          }
          Text(String(format: "%.1f sec", recordingDuration))
            .foregroundColor(.secondary)

          Button("Use this recording") {
            onSave(url)
            dismiss()
          }
          .buttonStyle(.borderedProminent)
        }
      }
    }
    .padding()
  }

  private func startRecording() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playAndRecord, mode: .default)
    try? session.setActive(true)

    let filename = "voice_\(UUID().uuidString.prefix(8)).m4a"
    let url = documentsDir.appendingPathComponent(filename)

    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]

    guard let recorder = try? AVAudioRecorder(url: url, settings: settings) else { return }
    recorder.record()
    isRecording = true
    recordedURL = nil
    recordingDuration = 0

    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      recordingDuration = recorder.currentTime
    }
    timer?.fire()
  }

  private func stopRecording() {
    timer?.invalidate()
    timer = nil
    isRecording = false
  }

  private func playAudio() {
    guard let url = recordedURL else { return }
    if isPlaying {
      audioPlayer?.stop()
      isPlaying = false
      return
    }
    audioPlayer = try? AVAudioPlayer(contentsOf: url)
    audioPlayer?.play()
    isPlaying = true
  }
}
