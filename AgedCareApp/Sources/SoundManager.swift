import AVFoundation
import AudioToolbox
import UIKit

final class SoundManager {
  static let shared = SoundManager()

  private var prepared = false

  private init() {}

  func prepare() {
    prepared = true
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: .mixWithOthers)
    try? session.setActive(true)
  }

  func playAlert(priority: Int) {
    if !prepared { prepare() }
    switch priority {
    case 1:
      AudioServicesPlayAlertSoundWithCompletion(kSystemSoundID_Vibrate) {}
      DispatchQueue.global().async { self.playTone(frequency: 880, duration: 0.5) }
      DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) { self.playTone(frequency: 1100, duration: 0.5) }
    case 2:
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
      DispatchQueue.global().async { self.playTone(frequency: 660, duration: 0.3) }
    default:
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
  }

  func playSOS() {
    if !prepared { prepare() }
    AudioServicesPlayAlertSoundWithCompletion(kSystemSoundID_Vibrate) {}
    let pattern: [(Double, Double)] = [
      (800, 0.3), (0, 0.2), (800, 0.3), (0, 0.2), (800, 0.3),
      (0, 0.4), (1000, 0.5), (0, 0.2), (1000, 0.5), (0, 0.2),
      (1000, 0.5), (0, 0.4), (800, 0.3), (0, 0.2), (800, 0.3),
      (0, 0.2), (800, 0.3),
    ]
    DispatchQueue.global().async {
      var delay = 0.0
      for note in pattern {
        let freq = note.0
        let dur = note.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
          AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        if freq > 0 {
          self.scheduleTone(frequency: freq, duration: dur, after: delay)
        }
        delay += dur + 0.05
      }
    }
  }

  func playAcknowledgement() {
    if !prepared { prepare() }
    AudioServicesPlaySystemSound(1103)
  }

  func vibrate() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
  }

  // MARK: - Programmatic tone generation

  private func playTone(frequency: Double, duration: Double, amplitude: Float = 0.3) {
    let sampleRate = 44100.0
    let totalSamples = Int(sampleRate * duration)
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(totalSamples)) else { return }
    buffer.frameLength = buffer.frameCapacity
    guard let samples = buffer.floatChannelData?[0] else { return }

    let twoPiF = 2.0 * .pi * frequency
    let invSampleRate = 1.0 / sampleRate

    for i in 0..<totalSamples {
      let t = Double(i) * invSampleRate
      var env = Float(t / 0.02)
      if t >= 0.02 {
        let decay = 1.0 - (t - duration + 0.02) / 0.02
        env = Float(max(0, decay))
      }
      let value = Float(sin(twoPiF * t)) * amplitude * env
      samples[i] = value
    }

    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    try? engine.start()
    player.scheduleBuffer(buffer, at: nil)
    player.play()
    Thread.sleep(forTimeInterval: duration + 0.1)
    engine.stop()
  }

  private func scheduleTone(frequency: Double, duration: Double, after delay: Double, amplitude: Float = 0.3) {
    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
      self.playTone(frequency: frequency, duration: duration, amplitude: amplitude)
    }
  }
}
