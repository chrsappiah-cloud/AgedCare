import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
  static let shared = WatchConnectivityService()

  @Published var isReachable = false
  @Published var watchContext: WatchContext?
  @Published var lastMessage: [String: Any]?

  struct WatchContext {
    let isComplicationEnabled: Bool
  }

  private override init() {
    super.init()
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  func sendSOSAlert(facilityId: String, residentId: String) {
    sendMessage([
      "type": "sos_alert",
      "facilityId": facilityId,
      "residentId": residentId,
      "timestamp": ISO8601DateFormatter().string(from: Date()),
    ])
  }

  func sendVitalUpdate(facilityId: String, residentId: String, metric: String, value: Double) {
    sendMessage([
      "type": "vital_update",
      "facilityId": facilityId,
      "residentId": residentId,
      "metric": metric,
      "value": value,
      "timestamp": ISO8601DateFormatter().string(from: Date()),
    ])
  }

  func sendAlertUpdate(alertJSON: String) {
    sendMessage([
      "type": "alert_update",
      "payload": alertJSON,
      "timestamp": ISO8601DateFormatter().string(from: Date()),
    ])
  }

  func transferUserInfo(_ dict: [String: Any]) {
    guard WCSession.default.activationState == .activated else { return }
    WCSession.default.transferUserInfo(dict)
  }

  private func sendMessage(_ dict: [String: Any]) {
    guard WCSession.default.activationState == .activated else { return }
    if WCSession.default.isReachable {
      WCSession.default.sendMessage(dict, replyHandler: nil) { error in
        print("[WatchConnectivity] sendMessage error: \(error.localizedDescription)")
      }
    } else {
      WCSession.default.transferUserInfo(dict)
    }
  }
}

extension WatchConnectivityService: WCSessionDelegate {
  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }

  nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    Task { @MainActor in
      isReachable = session.isReachable
    }
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in
      isReachable = session.isReachable
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    Task { @MainActor in
      lastMessage = message
      handleWatchMessage(message)
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    Task { @MainActor in
      lastMessage = userInfo
      handleWatchMessage(userInfo)
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    Task { @MainActor in
      lastMessage = applicationContext
    }
  }

  nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
    Task { @MainActor in
      watchContext = WatchContext(isComplicationEnabled: session.isComplicationEnabled)
    }
  }

  @MainActor
  private func handleWatchMessage(_ message: [String: Any]) {
    guard let type = message["type"] as? String else { return }
    switch type {
    case "sos_from_watch":
      NotificationCenter.default.post(name: .watchSOSTriggered, object: message)
    case "request_context":
      let context = buildContextPayload()
      transferUserInfo(["type": "context_update", "payload": context])
    default:
      break
    }
  }

  @MainActor
  private func buildContextPayload() -> [String: Any] {
    [
      "appName": "AgedCare",
      "timestamp": ISO8601DateFormatter().string(from: Date()),
    ]
  }
}

extension Notification.Name {
  static let watchSOSTriggered = Notification.Name("watchSOSTriggered")
}
