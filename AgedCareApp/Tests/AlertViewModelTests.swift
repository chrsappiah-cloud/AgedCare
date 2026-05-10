import Testing
import Foundation
@testable import AgedCareShared
@testable import AgedCareApp

final class MockAlertRepository: AlertsRepositoryProtocol {
  var alerts: [AlertModel] = []
  var createFallAlertResult: Int64 = 0
  var createSOSAlertResult: Int64 = 0
  var error: Error?

  func createFallAlert(facilityId: UUID, residentId: UUID, priority: Int) async throws -> Int64 {
    if let error { throw error }
    return createFallAlertResult
  }

  func createSOSAlert(facilityId: UUID, residentId: UUID) async throws -> Int64 {
    if let error { throw error }
    return createSOSAlertResult
  }

  func getOpenAlerts(facilityId: UUID) async throws -> [AlertModel] {
    if let error { throw error }
    return alerts
  }

  func acknowledgeAlert(alertId: Int64, staffId: UUID) async throws {
    if let error { throw error }
  }

  func closeAlert(alertId: Int64, notes: String) async throws {
    if let error { throw error }
  }
}

@MainActor
struct AlertViewModelTests {

  @Test("loadAlerts populates alerts on success")
  func loadAlertsSuccess() async throws {
    let mock = MockAlertRepository()
    mock.alerts = [
      AlertModel(id: 1, residentId: UUID(), type: "fall", status: "open", priority: 3, createdAt: Date()),
    ]
    let vm = AlertViewModel(alertsRepository: mock, facilityId: UUID())
    #expect(vm.alerts.isEmpty)
    #expect(!vm.isLoading)

    await vm.loadAlerts()

    #expect(vm.alerts.count == 1)
    #expect(vm.alerts[0].id == 1)
    #expect(vm.isLoading == false)
    #expect(vm.loadError == nil)
  }

  @Test("loadAlerts sets error on failure")
  func loadAlertsFailure() async throws {
    struct TestError: Error, LocalizedError {
      var errorDescription: String? { "network error" }
    }
    let mock = MockAlertRepository()
    mock.error = TestError()
    let vm = AlertViewModel(alertsRepository: mock, facilityId: UUID())

    await vm.loadAlerts()

    #expect(vm.alerts.isEmpty)
    #expect(vm.loadError == "network error")
    #expect(vm.isLoading == false)
  }

  @Test("filteredAlerts returns all by default")
  func filterAll() {
    let mock = MockAlertRepository()
    let vm = AlertViewModel(alertsRepository: mock, facilityId: UUID())
    vm.alerts = [
      AlertModel(id: 1, residentId: UUID(), type: "fall", status: "open", priority: 3, createdAt: Date()),
      AlertModel(id: 2, residentId: UUID(), type: "vitaltrend", status: "open", priority: 2, createdAt: Date()),
    ]
    #expect(vm.filteredAlerts.count == 2)
  }

  @Test("filteredAlerts filters falls")
  func filterFalls() {
    let mock = MockAlertRepository()
    let vm = AlertViewModel(alertsRepository: mock, facilityId: UUID())
    vm.alerts = [
      AlertModel(id: 1, residentId: UUID(), type: "fall", status: "open", priority: 3, createdAt: Date()),
      AlertModel(id: 2, residentId: UUID(), type: "vitaltrend", status: "open", priority: 2, createdAt: Date()),
    ]
    vm.filter = .falls
    #expect(vm.filteredAlerts.count == 1)
    #expect(vm.filteredAlerts[0].type == "fall")
  }

  @Test("filteredAlerts filters vitals")
  func filterVitals() {
    let mock = MockAlertRepository()
    let vm = AlertViewModel(alertsRepository: mock, facilityId: UUID())
    vm.alerts = [
      AlertModel(id: 1, residentId: UUID(), type: "fall", status: "open", priority: 3, createdAt: Date()),
      AlertModel(id: 2, residentId: UUID(), type: "vitaltrend", status: "open", priority: 2, createdAt: Date()),
      AlertModel(id: 3, residentId: UUID(), type: "manualSOS", status: "open", priority: 1, createdAt: Date()),
    ]
    vm.filter = .vitals
    #expect(vm.filteredAlerts.count == 1)
    #expect(vm.filteredAlerts[0].type == "vitaltrend")
  }

  @Test("replaceRepository swaps repository")
  func replaceRepo() {
    let mock1 = MockAlertRepository()
    let mock2 = MockAlertRepository()
    let vm = AlertViewModel(alertsRepository: mock1, facilityId: UUID())
    #expect(vm.alertsRepository as? MockAlertRepository === mock1)

    vm.replaceRepository(with: mock2)
    #expect(vm.alertsRepository as? MockAlertRepository === mock2)
  }
}
