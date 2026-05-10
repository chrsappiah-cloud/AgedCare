import Foundation
import UserNotifications
import UIKit
import AgedCareShared
#if canImport(CloudKit)
import CloudKit
#endif

public enum PushNotificationError: LocalizedError {
  case notRegistered
  case denied

  public var errorDescription: String? {
    switch self {
    case .notRegistered: return "Not registered for push notifications"
    case .denied: return "Push notification permission denied"
    }
  }
}

@MainActor
public final class PushNotificationService: NSObject {
  public static let shared = PushNotificationService()
  private var deviceToken: String?
  private var onAlertReceived: ((AlertModel) -> Void)?

  private override init() {
    super.init()
  }

  // MARK: - Registration

  public func register() async throws {
    let center = UNUserNotificationCenter.current()
    center.delegate = self

    let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
    let granted = try await center.requestAuthorization(options: options)
    guard granted else { throw PushNotificationError.denied }
  }

  public func registerForRemoteNotifications() {
    UIApplication.shared.registerForRemoteNotifications()
  }

  public func didRegisterForRemoteNotifications(with deviceToken: Data) {
    self.deviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
  }

  public func didFailToRegisterForRemoteNotifications(with error: Error) {
    print("⚠️ Push registration failed: \(error.localizedDescription)")
  }

  public var token: String? { deviceToken }

  // MARK: - Handler

  public func setAlertHandler(_ handler: @escaping (AlertModel) -> Void) {
    onAlertReceived = handler
  }

  public func handleNotificationResponse(_ response: UNNotificationResponse) async {
    let userInfo = response.notification.request.content.userInfo

    #if canImport(CloudKit)
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      let sync = CloudKitAlertSync.shared
      await sync.handleRemoteNotification(userInfo)
    }
    #endif
  }
}

// MARK: - UNUserNotificationCenterDelegate

@MainActor
extension PushNotificationService: UNUserNotificationCenterDelegate {
  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    return [.banner, .sound, .badge]
  }

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    await handleNotificationResponse(response)
  }
}

#if canImport(CloudKit)
extension PushNotificationService {
  public func subscribeAndRegister() async throws {
    try await register()
    registerForRemoteNotifications()
    try await CloudKitAlertSync.shared.subscribeToChanges()
  }
}
#endif
