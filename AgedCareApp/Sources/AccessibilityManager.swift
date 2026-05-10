import SwiftUI
import Combine

@MainActor
final class AccessibilityManager: ObservableObject {
  static let shared = AccessibilityManager()

  @Published var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
  @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
  @Published var isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
  @Published var isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
  @Published var isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
  @Published var isButtonShapesEnabled = UIAccessibility.buttonShapesEnabled
  @Published var preferredContentSizeCategory: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory

  private var observers: [NSObjectProtocol] = []

  private init() {
    let center = NotificationCenter.default
    observers = [
      center.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: .main) { _ in
        Task { @MainActor in AccessibilityManager.shared.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning }
      },
      center.addObserver(forName: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil, queue: .main) { _ in
        Task { @MainActor in AccessibilityManager.shared.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled }
      },
      center.addObserver(forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil, queue: .main) { _ in
        Task { @MainActor in AccessibilityManager.shared.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled }
      },
      center.addObserver(forName: UIAccessibility.boldTextStatusDidChangeNotification, object: nil, queue: .main) { _ in
        Task { @MainActor in AccessibilityManager.shared.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled }
      },
      center.addObserver(forName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification, object: nil, queue: .main) { _ in
        Task { @MainActor in AccessibilityManager.shared.isButtonShapesEnabled = UIAccessibility.buttonShapesEnabled }
      },
      center.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { _ in
        Task { @MainActor in AccessibilityManager.shared.preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory }
      },
    ]
  }

  deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
  }

  var dynamicTypeScaleFactor: CGFloat {
    switch preferredContentSizeCategory {
    case .extraSmall: return 0.85
    case .small: return 0.92
    case .medium: return 1.0
    case .large: return 1.0
    case .extraLarge: return 1.08
    case .extraExtraLarge: return 1.15
    case .extraExtraExtraLarge: return 1.23
    case .accessibilityMedium: return 1.35
    case .accessibilityLarge: return 1.5
    case .accessibilityExtraLarge: return 1.65
    case .accessibilityExtraExtraLarge: return 1.8
    case .accessibilityExtraExtraExtraLarge: return 2.0
    default: return 1.0
    }
  }

  var scaledFontSize: (_ baseSize: CGFloat) -> CGFloat {
    { base in base * self.dynamicTypeScaleFactor }
  }

  func announcement(_ message: String) {
    UIAccessibility.post(notification: .announcement, argument: message)
  }

  func layoutChanged() {
    UIAccessibility.post(notification: .layoutChanged, argument: nil)
  }

  func screenChanged() {
    UIAccessibility.post(notification: .screenChanged, argument: nil)
  }
}
