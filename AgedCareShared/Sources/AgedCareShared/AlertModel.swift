import Foundation

public struct AlertModel: Identifiable, Decodable {
  public let id: Int64
  public let residentId: UUID
  public let type: String
  public let status: String
  public let priority: Int
  public let createdAt: Date
  public let assignedStaffId: UUID?

  enum CodingKeys: String, CodingKey {
    case id
    case residentId = "resident_id"
    case type
    case status
    case priority
    case createdAt = "created_at"
    case assignedStaffId = "assigned_to"
  }
}

public struct FallDetectionEvent {
  public let timestamp: Date
  public let magnitude: Double
  public let confidence: Double

  public init(timestamp: Date, magnitude: Double, confidence: Double) {
    self.timestamp = timestamp
    self.magnitude = magnitude
    self.confidence = confidence
  }
}

// MARK: - Fall Alert

public struct CreateFallAlertRequest: Encodable {
  public let p_facility_id: String
  public let p_resident_id: String
  public let p_priority: Int
  public init(p_facility_id: String, p_resident_id: String, p_priority: Int) {
    self.p_facility_id = p_facility_id; self.p_resident_id = p_resident_id; self.p_priority = p_priority
  }
}

public struct CreateFallAlertResponse: Decodable {
  public let alert_id: Int64
}

public struct GetOpenAlertsRequest: Encodable {
  public let p_facility_id: String
  public init(p_facility_id: String) { self.p_facility_id = p_facility_id }
}

// MARK: - SOS Alert

public struct CreateSOSAlertRequest: Encodable {
  public let p_facility_id: String
  public let p_resident_id: String
  public init(p_facility_id: String, p_resident_id: String) {
    self.p_facility_id = p_facility_id; self.p_resident_id = p_resident_id
  }
}

public struct CreateSOSAlertResponse: Decodable {
  public let alert_id: Int64
}

// MARK: - Acknowledge / Close

public struct AcknowledgeAlertRequest: Encodable {
  public let p_alert_id: Int64
  public let p_staff_id: String
  public init(p_alert_id: Int64, p_staff_id: String) {
    self.p_alert_id = p_alert_id; self.p_staff_id = p_staff_id
  }
}

public struct CloseAlertRequest: Encodable {
  public let p_alert_id: Int64
  public let p_notes: String
  public init(p_alert_id: Int64, p_notes: String) {
    self.p_alert_id = p_alert_id; self.p_notes = p_notes
  }
}

// MARK: - Residents

public struct ResidentDTO: Decodable {
  public let id: UUID
  public let facility_id: UUID
  public let name: String
  public let risk_level: String?
  public let date_of_birth: String?
}

public struct GetResidentsRequest: Encodable {
  public let p_facility_id: String
  public init(p_facility_id: String) { self.p_facility_id = p_facility_id }
}

// MARK: - Fall Summary

public struct GetFallSummaryRequest: Encodable {
  public let p_resident_id: String
  public let p_days: Int
  public init(p_resident_id: String, p_days: Int) {
    self.p_resident_id = p_resident_id; self.p_days = p_days
  }
}

// MARK: - Timeline

public struct GetTimelineRequest: Encodable {
  public let p_resident_id: String
  public let p_limit: Int
  public init(p_resident_id: String, p_limit: Int = 50) {
    self.p_resident_id = p_resident_id; self.p_limit = p_limit
  }
}

public struct TimelineEntryDTO: Decodable {
  public let kind: String
  public let ts: String
  public let summary: String
}

// MARK: - Facility Stats

public struct GetFacilityStatsRequest: Encodable {
  public let p_facility_id: String
  public init(p_facility_id: String) { self.p_facility_id = p_facility_id }
}

public struct FacilityStatsDTO: Decodable {
  public let falls_last_7d: Int
  public let open_alerts: Int
  public let avg_acknowledge_minutes: Int
}
