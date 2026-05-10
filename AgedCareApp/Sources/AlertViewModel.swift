import Foundation
import AgedCareShared

enum AlertFilter: String, CaseIterable {
  case all
  case assignedToMe
  case falls
  case vitals
}

@MainActor
final class AlertViewModel: ObservableObject {
  @Published var alerts: [AlertModel] = []
  @Published var filter: AlertFilter = .all
  @Published var isLoading = false
  @Published var loadError: String?

  var filteredAlerts: [AlertModel] {
    switch filter {
    case .all:
      return alerts
    case .assignedToMe:
      return alerts
    case .falls:
      return alerts.filter { $0.type.lowercased() == "fall" }
    case .vitals:
      return alerts.filter { $0.type.lowercased() == "vitaltrend" }
    }
  }

  private(set) var alertsRepository: AlertsRepositoryProtocol
  private let facilityId: UUID

  init(alertsRepository: AlertsRepositoryProtocol, facilityId: UUID) {
    self.alertsRepository = alertsRepository
    self.facilityId = facilityId
  }

  func replaceRepository(with repo: AlertsRepositoryProtocol) {
    alertsRepository = repo
  }

  func loadAlerts() async {
    isLoading = true
    loadError = nil
    defer { isLoading = false }
    do {
      alerts = try await alertsRepository.getOpenAlerts(facilityId: facilityId)
    } catch {
      loadError = error.localizedDescription
    }
  }

  func acknowledge(alertId: Int64, staffId: UUID) async throws {
    try await alertsRepository.acknowledgeAlert(alertId: alertId, staffId: staffId)
    try await loadAlerts()
  }

  func close(alertId: Int64, notes: String) async throws {
    try await alertsRepository.closeAlert(alertId: alertId, notes: notes)
    try await loadAlerts()
  }
}
