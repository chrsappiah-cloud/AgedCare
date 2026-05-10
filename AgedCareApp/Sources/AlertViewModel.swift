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
      return alerts.filter { $0.assignedStaffId == staffId }
    case .falls:
      return alerts.filter { $0.type.lowercased() == "fall" }
    case .vitals:
      return alerts.filter { $0.type.lowercased() == "vitaltrend" }
    }
  }

  var alertsRepository: AlertsRepositoryProtocol?
  private let facilityId: UUID
  private let staffId: UUID

  init(facilityId: UUID, staffId: UUID) {
    self.facilityId = facilityId
    self.staffId = staffId
  }

  func loadAlerts() async {
    isLoading = true
    loadError = nil
    defer { isLoading = false }
    do {
      guard let repo = alertsRepository else {
        loadError = "Repository not initialized"
        return
      }
      alerts = try await repo.getOpenAlerts(facilityId: facilityId)
    } catch {
      loadError = error.localizedDescription
    }
  }

  func acknowledge(alertId: Int64, staffId: UUID) async throws {
    guard let repo = alertsRepository else { return }
    try await repo.acknowledgeAlert(alertId: alertId, staffId: staffId)
    try await loadAlerts()
  }

  func close(alertId: Int64, notes: String) async throws {
    guard let repo = alertsRepository else { return }
    try await repo.closeAlert(alertId: alertId, notes: notes)
    try await loadAlerts()
  }
}
