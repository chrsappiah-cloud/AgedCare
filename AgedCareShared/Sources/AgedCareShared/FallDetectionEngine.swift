import Foundation

#if os(iOS)
import CoreMotion

public final class FallDetectionEngine {
  private let manager = CMMotionManager()
  private let queue = OperationQueue()
  private let magnitudeThreshold: Double

  public var onEvent: ((FallDetectionEvent) -> Void)?

  public init(magnitudeThreshold: Double = 2.5) {
    self.magnitudeThreshold = magnitudeThreshold
  }

  public func start() {
    guard manager.isDeviceMotionAvailable else { return }
    manager.deviceMotionUpdateInterval = 1.0 / 25.0
    manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
      guard let self, let motion else { return }
      self.handle(motion)
    }
  }

  public func stop() {
    manager.stopDeviceMotionUpdates()
  }

  private func handle(_ motion: CMDeviceMotion) {
    let a = motion.userAcceleration
    let magnitude = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
    if magnitude > magnitudeThreshold {
      let event = FallDetectionEvent(timestamp: Date(), magnitude: magnitude, confidence: 0.0)
      DispatchQueue.main.async {
        self.onEvent?(event)
      }
    }
  }
}
#else
public final class FallDetectionEngine {
  public var onEvent: ((FallDetectionEvent) -> Void)?

  public init(magnitudeThreshold: Double = 2.5) {}

  public func start() {}
  public func stop() {}
}
#endif
