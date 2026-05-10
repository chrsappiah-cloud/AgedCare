import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechRecognitionService: ObservableObject {
    static let shared = SpeechRecognitionService()

    @Published var isAuthorized = false
    @Published var isTranscribing = false
    @Published var liveTranscript = ""
    @Published var errorMessage: String?

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-AU"))
    }

    func requestAuthorization() async {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        isAuthorized = (status == .authorized)
        if !isAuthorized {
            errorMessage = "Speech recognition not authorized"
        }
    }

    func startTranscription(onKeywordDetected: @escaping (String, String) -> Void) throws {
        guard let recognizer, recognizer.isAvailable else {
            throw CaptureError.microphoneUnavailable
        }

        stopTranscription()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isTranscribing = true

        let distressKeywords = ["help", "fall", "fallen", "pain", "hurt", "nurse", "emergency", "can't breathe", "chest pain", "dizzy"]

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    let text = result.bestTranscription.formattedString
                    self.liveTranscript = text

                    let lowerText = text.lowercased()
                    for keyword in distressKeywords {
                        if lowerText.contains(keyword) {
                            onKeywordDetected(keyword, text)
                        }
                    }
                }

                if error != nil || (result?.isFinal ?? false) {
                    self.stopTranscription()
                    if error != nil, self.isTranscribing {
                        try? self.startTranscription(onKeywordDetected: onKeywordDetected)
                    }
                }
            }
        }
    }

    func stopTranscription() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }
}
