import SwiftUI
import UserNotifications
import AgedCareShared

@main
struct AgedCareApp: App {
  @StateObject private var container = DependencyContainer()
  @State private var healthInitError: String?

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(container)
        .overlay {
          if let error = healthInitError {
            Text(error)
              .font(.caption)
              .foregroundColor(.orange)
              .padding(8)
              .background(.ultraThinMaterial)
              .cornerRadius(8)
              .padding(.top, 50)
              .frame(maxHeight: .infinity, alignment: .top)
          }
        }
        .task {
          await initializeServices()
        }
    }
  }

  private func initializeServices() async {
    // 1. Push notifications + CloudKit subscription
    do {
      try await PushNotificationService.shared.register()
      PushNotificationService.shared.registerForRemoteNotifications()
    } catch {
      print("ℹ️ Push registration skipped: \(error.localizedDescription)")
    }

    // 2. HealthKit
    if HealthKitService.shared.isAvailable {
      do {
        try await HealthKitService.shared.requestAuthorization()
      } catch {
        healthInitError = "HealthKit: \(error.localizedDescription)"
      }
    }

    // 3. CloudKit alert sync subscription
    #if canImport(CloudKit)
    CloudKitAlertSync.shared = CloudKitAlertSync()
    if let cloudKit = CloudKitAlertSync.shared {
      do {
        try await cloudKit.subscribeToChanges()
      } catch {
        print("ℹ️ CloudKit subscription deferred: \(error.localizedDescription)")
      }
    } else {
      print("ℹ️ CloudKit not available (running on simulator or no iCloud account)")
    }
    #endif
  }
}
