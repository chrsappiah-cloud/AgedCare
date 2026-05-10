import Foundation

@MainActor
public protocol FallServiceDelegate: AnyObject {
  func fallServiceDidTriggerPossibleFall(_ service: FallService, event: FallDetectionEvent)
  func fallService(_ service: FallService, didFailWith error: Error)
}

public final class FallService {
  private let engine: FallDetectionEngine
  private let alertsRepository: AlertsRepositoryProtocol
  private let facilityId: UUID
  private let residentId: UUID

  public weak var delegate: FallServiceDelegate?

  public init(
    engine: FallDetectionEngine,
    alertsRepository: AlertsRepositoryProtocol,
    facilityId: UUID,
    residentId: UUID
  ) {
    self.engine = engine
    self.alertsRepository = alertsRepository
    self.facilityId = facilityId
    self.residentId = residentId
    engine.onEvent = { [weak self] event in
      Task { await self?.handle(event: event) }
    }
  }

  public func start() {
    engine.start()
  }

  public func stop() {
    engine.stop()
  }

  @MainActor
  private func handle(event: FallDetectionEvent) async {
    delegate?.fallServiceDidTriggerPossibleFall(self, event: event)
    do {
      _ = try await alertsRepository.createFallAlert(
        facilityId: facilityId,
        residentId: residentId,
        priority: 3
      )
    } catch {
      delegate?.fallService(self, didFailWith: error)
    }
  }
}
