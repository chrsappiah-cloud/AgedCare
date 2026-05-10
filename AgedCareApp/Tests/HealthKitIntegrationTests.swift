import Testing
import Foundation
@testable import AgedCareShared
@testable import AgedCareApp

final class MockResidentsRepository: ResidentsRepositoryProtocol {
  var vitalEvents: [(facilityId: UUID, residentId: UUID, metric: String, value: Double, timestamp: Date)] = []
  var residents: [ResidentDTO] = []
  var fallCounts: [Int: Int] = [:]
  var timelines: [UUID: [TimelineEntryDTO]] = [:]
  var error: Error?

  func getResidents(facilityId: UUID) async throws -> [ResidentDTO] {
    if let error { throw error }
    return residents
  }

  func getFallCount(residentId: UUID, days: Int) async throws -> Int {
    if let error { throw error }
    return fallCounts[days] ?? 0
  }

  func getTimeline(residentId: UUID, limit: Int) async throws -> [TimelineEntryDTO] {
    if let error { throw error }
    return timelines[residentId] ?? []
  }

  func recordVitalEvent(facilityId: UUID, residentId: UUID, metric: String, value: Double, timestamp: Date) async throws {
    if let error { throw error }
    vitalEvents.append((facilityId, residentId, metric, value, timestamp))
  }
}

@MainActor
struct MonitoringCoordinatorTests {

  @Test("MonitoringCoordinator starts with monitoring disabled")
  func initialState() {
    let mockAlerts = MockAlertRepository()
    let mockResidents = MockResidentsRepository()
    let coordinator = MonitoringCoordinator(
      fallService: FallService(
        engine: FallDetectionEngine(),
        alertsRepository: mockAlerts,
        facilityId: UUID(),
        residentId: UUID()
      ),
      facilityId: UUID(),
      residentId: UUID(),
      alertsRepository: mockAlerts,
      residentsRepository: mockResidents
    )
    #expect(coordinator.monitoringEnabled == false)
    #expect(coordinator.healthKitAuthorized == false)
    #expect(coordinator.latestHeartRate == nil)
  }

  @Test("startMonitoring enables monitoring")
  func startMonitoring() {
    let mockAlerts = MockAlertRepository()
    let mockResidents = MockResidentsRepository()
    let coordinator = MonitoringCoordinator(
      fallService: FallService(
        engine: FallDetectionEngine(),
        alertsRepository: mockAlerts,
        facilityId: UUID(),
        residentId: UUID()
      ),
      facilityId: UUID(),
      residentId: UUID(),
      alertsRepository: mockAlerts,
      residentsRepository: mockResidents
    )
    coordinator.startMonitoring()
    #expect(coordinator.monitoringEnabled == true)
  }

  @Test("stopMonitoring disables monitoring")
  func stopMonitoring() {
    let mockAlerts = MockAlertRepository()
    let mockResidents = MockResidentsRepository()
    let coordinator = MonitoringCoordinator(
      fallService: FallService(
        engine: FallDetectionEngine(),
        alertsRepository: mockAlerts,
        facilityId: UUID(),
        residentId: UUID()
      ),
      facilityId: UUID(),
      residentId: UUID(),
      alertsRepository: mockAlerts,
      residentsRepository: mockResidents
    )
    coordinator.startMonitoring()
    #expect(coordinator.monitoringEnabled == true)
    coordinator.stopMonitoring()
    #expect(coordinator.monitoringEnabled == false)
  }

  @Test("HealthKit not available on simulator shows error")
  func healthKitNotAvailable() {
    let mockAlerts = MockAlertRepository()
    let mockResidents = MockResidentsRepository()
    let coordinator = MonitoringCoordinator(
      fallService: FallService(
        engine: FallDetectionEngine(),
        alertsRepository: mockAlerts,
        facilityId: UUID(),
        residentId: UUID()
      ),
      facilityId: UUID(),
      residentId: UUID(),
      alertsRepository: mockAlerts,
      residentsRepository: mockResidents
    )
    coordinator.startMonitoring()
    #expect(coordinator.healthKitAuthorized == false)
  }

  @Test("recordVitalEvent encodes and sends to repository")
  func testVitalRecording() async throws {
    let mockResidents = MockResidentsRepository()
    let facilityId = UUID(uuidString: "00000000-0000-4000-A000-000000000001")!
    let residentId = UUID(uuidString: "00000000-0000-4000-A000-000000000011")!
    let date = Date()

    try await mockResidents.recordVitalEvent(
      facilityId: facilityId,
      residentId: residentId,
      metric: "heart_rate",
      value: 72.0,
      timestamp: date
    )

    #expect(mockResidents.vitalEvents.count == 1)
    #expect(mockResidents.vitalEvents[0].metric == "heart_rate")
    #expect(mockResidents.vitalEvents[0].value == 72.0)
    #expect(mockResidents.vitalEvents[0].facilityId == facilityId)
    #expect(mockResidents.vitalEvents[0].residentId == residentId)
  }

  @Test("recordVitalEvent propagates repository error")
  func testVitalRecordingError() async {
    let mockResidents = MockResidentsRepository()
    mockResidents.error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "db error"])

    do {
      try await mockResidents.recordVitalEvent(
        facilityId: UUID(), residentId: UUID(),
        metric: "heart_rate", value: 72.0, timestamp: Date()
      )
      Issue.record("Expected error")
    } catch {
      #expect(error.localizedDescription == "db error")
    }
  }
}
