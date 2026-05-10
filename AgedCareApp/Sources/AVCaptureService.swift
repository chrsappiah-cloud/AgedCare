import AVFoundation
import UIKit
import Combine

enum CaptureError: LocalizedError {
    case cameraUnavailable
    case microphoneUnavailable
    case permissionDenied(String)
    case sessionConfigFailed(String)
    case recordingFailed(String)

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable: return "Camera is not available on this device"
        case .microphoneUnavailable: return "Microphone is not available on this device"
        case .permissionDenied(let resource): return "\(resource) access was denied"
        case .sessionConfigFailed(let msg): return "Capture session configuration failed: \(msg)"
        case .recordingFailed(let msg): return "Recording failed: \(msg)"
        }
    }
}

@MainActor
final class AVCaptureService: NSObject, ObservableObject {
    static let shared = AVCaptureService()

    @Published var isCameraAuthorized = false
    @Published var isMicrophoneAuthorized = false
    @Published var isVideoRecording = false
    @Published var isAudioRecording = false
    @Published var currentAudioLevel: Float = 0
    @Published var lastCapturedImage: UIImage?
    @Published var lastRecordingURL: URL?
    @Published var errorMessage: String?

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var levelTimer: Timer?

    private let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    override private init() {
        super.init()
    }

    // MARK: - Permission Requests

    func requestAllPermissions() async {
        await requestCameraPermission()
        await requestMicrophonePermission()
    }

    func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            isCameraAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isCameraAuthorized = false
        }
    }

    func requestMicrophonePermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            isMicrophoneAuthorized = true
        case .notDetermined:
            isMicrophoneAuthorized = await AVCaptureDevice.requestAccess(for: .audio)
        default:
            isMicrophoneAuthorized = false
        }
    }

    // MARK: - Camera Session Setup

    func setupCaptureSession() throws {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
              ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CaptureError.cameraUnavailable
        }

        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(videoInput) else {
            throw CaptureError.sessionConfigFailed("Cannot add video input")
        }
        session.addInput(videoInput)

        if let mic = AVCaptureDevice.default(for: .audio) {
            if let audioInput = try? AVCaptureDeviceInput(device: mic),
               session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
        }

        let movieOutput = AVCaptureMovieFileOutput()
        movieOutput.maxRecordedDuration = CMTime(seconds: 300, preferredTimescale: 600)
        guard session.canAddOutput(movieOutput) else {
            throw CaptureError.sessionConfigFailed("Cannot add movie output")
        }
        session.addOutput(movieOutput)
        videoOutput = movieOutput

        let photo = AVCapturePhotoOutput()
        guard session.canAddOutput(photo) else {
            throw CaptureError.sessionConfigFailed("Cannot add photo output")
        }
        session.addOutput(photo)
        photoOutput = photo

        session.commitConfiguration()
        captureSession = session
    }

    func startCaptureSession() {
        guard let session = captureSession, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func stopCaptureSession() {
        guard let session = captureSession, session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }

    var previewLayer: AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    // MARK: - Photo Capture

    func capturePhoto() {
        guard let photoOutput else {
            errorMessage = "Photo output not configured"
            return
        }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate { [weak self] image in
            Task { @MainActor in
                self?.lastCapturedImage = image
            }
        })
    }

    // MARK: - Video Recording

    func startVideoRecording() throws {
        guard let output = videoOutput else {
            throw CaptureError.recordingFailed("Video output not configured")
        }
        guard !output.isRecording else { return }

        let filename = "video_\(ISO8601DateFormatter().string(from: Date())).mov"
        let url = documentsDir.appendingPathComponent(filename)

        output.startRecording(to: url, recordingDelegate: VideoCaptureDelegate { [weak self] url, error in
            Task { @MainActor in
                self?.isVideoRecording = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.lastRecordingURL = url
                }
            }
        })
        isVideoRecording = true
    }

    func stopVideoRecording() {
        videoOutput?.stopRecording()
    }

    // MARK: - Audio Recording (standalone, no camera)

    func startAudioRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let filename = "audio_\(ISO8601DateFormatter().string(from: Date())).m4a"
        let url = documentsDir.appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128_000,
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.record()
        audioRecorder = recorder
        isAudioRecording = true

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self, weak recorder] _ in
            guard let recorder else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            let normalized = max(0, min(1, (power + 60) / 60))
            Task { @MainActor [weak self] in
                self?.currentAudioLevel = Float(normalized)
            }
        }
    }

    func stopAudioRecording() -> URL? {
        levelTimer?.invalidate()
        levelTimer = nil
        guard let recorder = audioRecorder else { return nil }
        recorder.stop()
        let url = recorder.url
        audioRecorder = nil
        isAudioRecording = false
        currentAudioLevel = 0
        lastRecordingURL = url
        return url
    }

    // MARK: - Audio Engine (real-time tap for level monitoring / analysis)

    func startAudioEngine(bufferHandler: @escaping (AVAudioPCMBuffer) -> Void) throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            bufferHandler(buffer)
        }

        try engine.start()
        audioEngine = engine
    }

    func stopAudioEngine() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }

    // MARK: - Cleanup

    func tearDown() {
        stopCaptureSession()
        stopAudioEngine()
        _ = stopAudioRecording()
        stopVideoRecording()
        captureSession = nil
    }
}

// MARK: - Photo Capture Delegate

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }
}

// MARK: - Video Recording Delegate

private final class VideoCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    let completion: (URL?, Error?) -> Void

    init(completion: @escaping (URL?, Error?) -> Void) {
        self.completion = completion
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        completion(error == nil ? outputFileURL : nil, error)
    }
}
