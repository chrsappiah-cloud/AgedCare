import SwiftUI
import UserNotifications
import AVFoundation

@main
struct AgedCareApp: App {
  @StateObject private var container = DependencyContainer()
  @StateObject private var captureService = AVCaptureService.shared
  @StateObject private var speechService = SpeechRecognitionService.shared
  @State private var healthInitError: String?

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(container)
        .environmentObject(captureService)
        .environmentObject(speechService)
        .overlay(alignment: .top) {
          if let error = healthInitError {
            Text(error)
              .font(.caption)
              .foregroundColor(.orange)
              .padding(8)
              .background(.ultraThinMaterial)
              .cornerRadius(8)
              .padding(.top, 50)
              .transition(.move(edge: .top).combined(with: .opacity))
          }
        }
        .task {
          await initializeServices()
        }
    }
  }

  private func initializeServices() async {
    // 1. Push notifications
    do {
      try await PushNotificationService.shared.register()
      PushNotificationService.shared.registerForRemoteNotifications()
    } catch {
      print("ℹ️ Push registration skipped: \(error.localizedDescription)")
    }

    // 2. HealthKit
    do {
      if HealthKitService.shared.isAvailable {
        try await HealthKitService.shared.requestAuthorization()
      } else {
        healthInitError = "HealthKit: Not available on this device"
      }
    } catch {
      healthInitError = "HealthKit: \(error.localizedDescription)"
      print("ℹ️ HealthKit init skipped: \(error.localizedDescription)")
    }

    // 3. Camera & Microphone permissions
    await captureService.requestAllPermissions()

    // 4. Speech Recognition
    await speechService.requestAuthorization()

    // 5. CloudKit alert sync
    #if canImport(CloudKit)
    do {
      CloudKitAlertSync.shared = CloudKitAlertSync()
      if let cloudKit = CloudKitAlertSync.shared {
        try await cloudKit.subscribeToChanges()
      }
    } catch {
      print("ℹ️ CloudKit subscription deferred: \(error.localizedDescription)")
    }
    #endif

    // Auto-dismiss HealthKit banner after 5 seconds
    if healthInitError != nil {
      try? await Task.sleep(nanoseconds: 5_000_000_000)
      withAnimation { healthInitError = nil }
    }
  }
}
