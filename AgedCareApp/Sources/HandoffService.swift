import Foundation
import UserNotifications
import UIKit

enum HandoffAction: Codable, Equatable {
  case requestStaff(facilityId: String, residentId: String, residentName: String)
  case staffTakeover(staffId: String, staffName: String, facilityId: String)
  case sosAlert(facilityId: String, residentId: String)
  case vitalReading(facilityId: String, residentId: String, metric: String, value: Double)

  var notificationTitle: String {
    switch self {
    case .requestStaff: return "Resident Needs Assistance"
    case .staffTakeover: return "Staff Connected"
    case .sosAlert: return "SOS Alert"
    case .vitalReading: return "Vital Reading"
    }
  }

  var notificationBody: String {
    switch self {
    case .requestStaff(_, _, let name): return "\(name) has requested a staff member"
    case .staffTakeover(_, let name, _): return "\(name) is now monitoring this device"
    case .sosAlert(_, _): return "A resident has triggered an SOS alert"
    case .vitalReading(_, _, let metric, let value): return "\(metric): \(value)"
    }
  }
}

@MainActor
final class HandoffService: NSObject, ObservableObject {
  static let shared = HandoffService()

  @Published var pendingHandoff: HandoffAction?
  @Published var activeTransferToken: String?

  private var handoffCallback: ((HandoffAction) -> Void)?

  func startListening(callback: @escaping (HandoffAction) -> Void) {
    handoffCallback = callback
    registerForPushHandoffs()
  }

  func requestStaff(facilityId: String, residentId: String, residentName: String) {
    let action = HandoffAction.requestStaff(facilityId: facilityId, residentId: residentId, residentName: residentName)
    pendingHandoff = action
    postLocalNotification(for: action)
    handoffCallback?(action)
  }

  func staffTakeover(staffId: String, staffName: String, facilityId: String, session: SessionViewModel) {
    let action = HandoffAction.staffTakeover(staffId: staffId, staffName: staffName, facilityId: facilityId)
    pendingHandoff = action
    postLocalNotification(for: action)
    session.state = .onboarding
    handoffCallback?(action)
  }

  func acceptHandoff(token: String) {
    activeTransferToken = token
  }

  func clearHandoff() {
    pendingHandoff = nil
    activeTransferToken = nil
  }

  private func registerForPushHandoffs() {
    UNUserNotificationCenter.current().delegate = self
  }

  private func postLocalNotification(for action: HandoffAction) {
    let content = UNMutableNotificationContent()
    content.title = action.notificationTitle
    content.body = action.notificationBody
    content.sound = .default
    content.userInfo = handoffUserInfo(for: action)
    content.categoryIdentifier = "HANDOFF"
    let request = UNNotificationRequest(
      identifier: "handoff_\(UUID().uuidString)",
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
  }

  private func handoffUserInfo(for action: HandoffAction) -> [String: Any] {
    var info: [String: Any] = ["handoff": true]
    switch action {
    case .requestStaff(let fid, let rid, let name):
      info["action"] = "requestStaff"
      info["facilityId"] = fid
      info["residentId"] = rid
      info["residentName"] = name
    case .staffTakeover(let sid, let sname, let fid):
      info["action"] = "staffTakeover"
      info["staffId"] = sid
      info["staffName"] = sname
      info["facilityId"] = fid
    case .sosAlert(let fid, let rid):
      info["action"] = "sosAlert"
      info["facilityId"] = fid
      info["residentId"] = rid
    case .vitalReading(let fid, let rid, let metric, let value):
      info["action"] = "vitalReading"
      info["facilityId"] = fid
      info["residentId"] = rid
      info["metric"] = metric
      info["value"] = value
    }
    return info
  }
}

extension HandoffService: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    guard userInfo["handoff"] as? Bool == true else {
      completionHandler()
      return
    }
    Task { @MainActor in
      handleHandoffNotification(userInfo)
      completionHandler()
    }
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    if userInfo["handoff"] as? Bool == true {
      completionHandler([.banner, .sound, .list])
    } else {
      completionHandler([.banner, .sound])
    }
  }

  @MainActor
  private func handleHandoffNotification(_ userInfo: [AnyHashable: Any]) {
    guard let action = userInfo["action"] as? String else { return }
    let fid = userInfo["facilityId"] as? String
    let rid = userInfo["residentId"] as? String
    switch action {
    case "requestStaff":
      if let fid, let rid {
        pendingHandoff = .requestStaff(facilityId: fid, residentId: rid, residentName: userInfo["residentName"] as? String ?? "Resident")
      }
    case "staffTakeover":
      if let sid = userInfo["staffId"] as? String, let sname = userInfo["staffName"] as? String, let fid {
        pendingHandoff = .staffTakeover(staffId: sid, staffName: sname, facilityId: fid)
      }
    case "sosAlert":
      if let fid, let rid {
        pendingHandoff = .sosAlert(facilityId: fid, residentId: rid)
      }
    default:
      break
    }
  }
}
