import SwiftUI
import WatchConnectivity

@main
struct AgedCareWatchApp: App {
  @StateObject private var watchViewModel = WatchViewModel()

  var body: some Scene {
    WindowGroup {
      WatchContentView()
        .environmentObject(watchViewModel)
        .onAppear { watchViewModel.activate() }
    }
  }
}

@MainActor
final class WatchViewModel: ObservableObject {
  @Published var alerts: [WatchAlertItem] = []
  @Published var heartRate: String = "--"
  @Published var bloodOxygen: String = "--"
  @Published var monitoringStatus: String = "Disconnected"
  @Published var isMonitoringActive = false
  @Published var lastSync: Date?

  private let session = WCSession.default

  func activate() {
    guard WCSession.isSupported() else { return }
    session.delegate = self
    session.activate()
  }

  func sendSOS() {
    session.sendMessage([
      "type": "sos_from_watch",
      "timestamp": ISO8601DateFormatter().string(from: Date()),
    ], replyHandler: nil)
    WKInterfaceDevice.current().play(.notification)
  }

  func requestContext() {
    session.sendMessage(["type": "request_context"], replyHandler: nil)
  }
}

extension WatchViewModel: WCSessionDelegate {
  nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    Task { @MainActor in
      if activationState == .activated {
        monitoringStatus = "Connected"
        requestContext()
      }
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    handleIncoming(message)
  }

  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    handleIncoming(userInfo)
  }

  nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    handleIncoming(applicationContext)
  }

  private func handleIncoming(_ data: [String: Any]) {
    Task { @MainActor in
      lastSync = Date()
      guard let type = data["type"] as? String else { return }
      switch type {
      case "sos_alert":
        isMonitoringActive = true
        WKInterfaceDevice.current().play(.notification)
      case "vital_update":
        if let metric = data["metric"] as? String, let value = data["value"] as? Double {
          if metric == "heart_rate" { heartRate = "\(Int(value))" }
          if metric == "blood_oxygen" { bloodOxygen = "\(Int(value * 100))%" }
        }
      case "alert_update":
        if let payload = data["payload"] as? String,
           let jsonData = payload.data(using: .utf8),
           let item = try? JSONDecoder().decode(WatchAlertItem.self, from: jsonData) {
          alerts.insert(item, at: 0)
          if alerts.count > 20 { alerts = Array(alerts.prefix(20)) }
        }
      case "context_update":
        if let payload = data["payload"] as? [String: Any] {
          heartRate = payload["latestHeartRate"] as? String ?? "--"
          bloodOxygen = payload["latestBloodOxygen"] as? String ?? "--"
        }
      default:
        break
      }
    }
  }
}

struct WatchAlertItem: Identifiable, Codable {
  let id: String
  let type: String
  let priority: Int
  let summary: String
  let timestamp: String
}
