import Foundation

public protocol AlertsRepositoryProtocol: AnyObject {
  func createFallAlert(facilityId: UUID, residentId: UUID, priority: Int) async throws -> Int64
  func createSOSAlert(facilityId: UUID, residentId: UUID) async throws -> Int64
  func getOpenAlerts(facilityId: UUID) async throws -> [AlertModel]
  func acknowledgeAlert(alertId: Int64, staffId: UUID) async throws
  func closeAlert(alertId: Int64, notes: String) async throws
}

public final class AlertsRepository: AlertsRepositoryProtocol {
  private let supabase: SupabaseClient

  public init(supabase: SupabaseClient) {
    self.supabase = supabase
  }

  public func createFallAlert(facilityId: UUID, residentId: UUID, priority: Int) async throws -> Int64 {
    let req = CreateFallAlertRequest(
      p_facility_id: facilityId.uuidString,
      p_resident_id: residentId.uuidString,
      p_priority: priority
    )
    let resp: CreateFallAlertResponse = try await supabase.rpc("create_fall_alert", payload: req)
    return resp.alert_id
  }

  public func createSOSAlert(facilityId: UUID, residentId: UUID) async throws -> Int64 {
    let req = CreateSOSAlertRequest(
      p_facility_id: facilityId.uuidString,
      p_resident_id: residentId.uuidString
    )
    let resp: CreateSOSAlertResponse = try await supabase.rpc("create_sos_alert", payload: req)
    return resp.alert_id
  }

  public func getOpenAlerts(facilityId: UUID) async throws -> [AlertModel] {
    let req = GetOpenAlertsRequest(p_facility_id: facilityId.uuidString)
    let alerts: [AlertModel] = try await supabase.rpc("get_open_alerts_for_facility", payload: req)
    return alerts
  }

  public func acknowledgeAlert(alertId: Int64, staffId: UUID) async throws {
    let req = AcknowledgeAlertRequest(p_alert_id: alertId, p_staff_id: staffId.uuidString)
    try await supabase.rpcVoid("acknowledge_alert", payload: req)
  }

  public func closeAlert(alertId: Int64, notes: String) async throws {
    let req = CloseAlertRequest(p_alert_id: alertId, p_notes: notes)
    try await supabase.rpcVoid("close_alert", payload: req)
  }
}
