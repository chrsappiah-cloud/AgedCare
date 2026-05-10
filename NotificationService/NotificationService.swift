import UserNotifications

class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler handler: @escaping (UNNotificationContent) -> Void
  ) {
    contentHandler = handler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    guard let best = bestAttemptContent else {
      handler(request.content)
      return
    }

    if let alertType = request.content.userInfo["alertType"] as? String {
      switch alertType {
      case "fall":
        best.title = "🚨 Fall Detected"
        best.subtitle = "A resident may have fallen"
      case "sos":
        best.title = "🆘 SOS Alert"
        best.subtitle = "Resident requested assistance"
      case "vitaltrend":
        best.title = "❤️ Vital Sign Alert"
        best.subtitle = "Abnormal reading detected"
      default:
        break
      }

      if let priority = request.content.userInfo["priority"] as? Int {
        switch priority {
        case 3: best.sound = UNNotificationSound.defaultCritical
        case 2: best.sound = UNNotificationSound.default
        default: best.sound = UNNotificationSound.default
        }
      }
    }

    handler(best)
  }

  override func serviceExtensionTimeWillExpire() {
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}
