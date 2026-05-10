import Testing
import Foundation
#if canImport(HealthKit)
import HealthKit
#endif
@testable import AgedCareShared

struct SupabaseClientTests {

  @Test("AnyEncodable wraps an encodable value")
  func anyEncodableEncoding() throws {
    let value = "test"
    let wrapped = AnyEncodable(value)
    let data = try JSONEncoder().encode(wrapped)
    let decoded = try JSONDecoder().decode(String.self, from: data)
    #expect(decoded == "test")
  }

  @Test("AnyCodable round-trips int")
  func anyCodableInt() throws {
    let original = AnyCodable(42)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.value as? Int == 42)
  }

  @Test("AnyCodable round-trips string")
  func anyCodableString() throws {
    let original = AnyCodable("hello")
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.value as? String == "hello")
  }

  @Test("AnyCodable round-trips double")
  func anyCodableDouble() throws {
    let original = AnyCodable(3.14)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.value as? Double == 3.14)
  }

  @Test("AnyCodable round-trips bool")
  func anyCodableBool() throws {
    let original = AnyCodable(true)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    #expect(decoded.value as? Bool == true)
  }

  @Test("AnyCodable round-trips dictionary")
  func anyCodableDict() throws {
    let dict: [String: Any] = ["a": 1, "b": "two"]
    let original = AnyCodable(dict)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
    let result = decoded.value as? [String: Any]
    #expect(result?["a"] as? Int == 1)
    #expect(result?["b"] as? String == "two")
  }

  @Test("SupabaseError cases")
  func supabaseErrorCases() {
    let httpErr = SupabaseError.httpError(404, Data())
    let decodingErr = SupabaseError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "")))
    #expect(httpErr.localizedDescription != "")
    #expect(decodingErr.localizedDescription != "")
  }
}

struct AlertModelTests {

  @Test("AlertModel decodes from JSON")
  func alertModelDecoding() throws {
    let json = """
    {
      "id": 1,
      "resident_id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
      "type": "fall",
      "status": "open",
      "priority": 3,
      "created_at": "2026-05-10T00:00:00Z"
    }
    """
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let model = try decoder.decode(AlertModel.self, from: data)
    #expect(model.id == 1)
    #expect(model.type == "fall")
    #expect(model.status == "open")
    #expect(model.priority == 3)
  }

  @Test("CreateFallAlertRequest encodes correctly")
  func createFallAlertRequest() throws {
    let req = CreateFallAlertRequest(
      p_facility_id: "abc-123",
      p_resident_id: "def-456",
      p_priority: 2
    )
    let data = try JSONEncoder().encode(req)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["p_facility_id"] as? String == "abc-123")
    #expect(json["p_resident_id"] as? String == "def-456")
    #expect(json["p_priority"] as? Int == 2)
  }

  @Test("CreateSOSAlertRequest encodes correctly")
  func createSOSAlertRequest() throws {
    let req = CreateSOSAlertRequest(p_facility_id: "fac1", p_resident_id: "res1")
    let data = try JSONEncoder().encode(req)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(json["p_facility_id"] as? String == "fac1")
    #expect(json["p_resident_id"] as? String == "res1")
  }

  @Test("CreateFallAlertResponse decodes")
  func createFallAlertResponse() throws {
    let json = #"{"alert_id": 42}"#
    let data = json.data(using: .utf8)!
    let resp = try JSONDecoder().decode(CreateFallAlertResponse.self, from: data)
    #expect(resp.alert_id == 42)
  }
}

struct FallDetectionEventTests {

  @Test("FallDetectionEvent initializes")
  func eventInit() {
    let date = Date()
    let event = FallDetectionEvent(timestamp: date, magnitude: 3.0, confidence: 0.95)
    #expect(event.timestamp == date)
    #expect(event.magnitude == 3.0)
    #expect(event.confidence == 0.95)
  }
}

#if canImport(HealthKit)

struct VitalAlertTests {

  @Test("detectAbnormalVitals returns highHeartRate above 120")
  func highHeartRate() {
    let reading = VitalReading(type: .heartRate, value: 130.0, unit: .count().unitDivided(by: .minute()), timestamp: Date())
    let alert = HealthKitService.shared.detectAbnormalVitals(reading: reading)
    #expect(alert != nil)
    if case .highHeartRate(let r) = alert! {
      #expect(r.value == 130.0)
    } else {
      Issue.record("Expected highHeartRate alert")
    }
  }

  @Test("detectAbnormalVitals returns lowHeartRate below 40")
  func lowHeartRate() {
    let reading = VitalReading(type: .heartRate, value: 35.0, unit: .count().unitDivided(by: .minute()), timestamp: Date())
    let alert = HealthKitService.shared.detectAbnormalVitals(reading: reading)
    #expect(alert != nil)
    if case .lowHeartRate(let r) = alert! {
      #expect(r.value == 35.0)
    } else {
      Issue.record("Expected lowHeartRate alert")
    }
  }

  @Test("detectAbnormalVitals returns lowBloodOxygen below 0.90")
  func lowBloodOxygen() {
    let reading = VitalReading(type: .oxygenSaturation, value: 0.85, unit: .percent(), timestamp: Date())
    let alert = HealthKitService.shared.detectAbnormalVitals(reading: reading)
    #expect(alert != nil)
    if case .lowBloodOxygen(let r) = alert! {
      #expect(r.value == 0.85)
    } else {
      Issue.record("Expected lowBloodOxygen alert")
    }
  }

  @Test("detectAbnormalVitals returns nil for normal heart rate")
  func normalHeartRate() {
    let reading = VitalReading(type: .heartRate, value: 72.0, unit: .count().unitDivided(by: .minute()), timestamp: Date())
    let alert = HealthKitService.shared.detectAbnormalVitals(reading: reading)
    #expect(alert == nil)
  }

  @Test("detectAbnormalVitals returns nil for normal blood oxygen")
  func normalBloodOxygen() {
    let reading = VitalReading(type: .oxygenSaturation, value: 0.97, unit: .percent(), timestamp: Date())
    let alert = HealthKitService.shared.detectAbnormalVitals(reading: reading)
    #expect(alert == nil)
  }

  @Test("detectAbnormalVitals returns nil for unknown type")
  func unknownType() {
    let reading = VitalReading(type: .stepCount, value: 5000.0, unit: .count(), timestamp: Date())
    let alert = HealthKitService.shared.detectAbnormalVitals(reading: reading)
    #expect(alert == nil)
  }
}

#endif

struct RecordVitalEventRequestTests {

  @Test("RecordVitalEventRequest encodes correctly")
  func requestEncoding() throws {
    let facilityId = UUID(uuidString: "00000000-0000-4000-A000-000000000001")!
    let residentId = UUID(uuidString: "00000000-0000-4000-A000-000000000011")!
    let date = Date(timeIntervalSince1970: 1715356800)
    let req = RecordVitalEventRequest(
      p_facility_id: facilityId, p_resident_id: residentId,
      p_metric: "heart_rate", p_value: 72.0, p_timestamp: date
    )
    let data = try JSONEncoder().encode(req)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect((json["p_facility_id"] as? String)?.lowercased() == "00000000-0000-4000-a000-000000000001")
    #expect((json["p_resident_id"] as? String)?.lowercased() == "00000000-0000-4000-a000-000000000011")
    #expect(json["p_metric"] as? String == "heart_rate")
    #expect(json["p_value"] as? Double == 72.0)
    #expect(json["p_timestamp"] as? String != nil)
  }
}

#if canImport(HealthKit)

struct HealthKitServiceTests {

  @Test("HealthKitService is singleton")
  func singleton() {
    let instance1 = HealthKitService.shared
    let instance2 = HealthKitService.shared
    #expect(instance1 === instance2)
  }

  @Test("HealthKitService requestAuthorization throws without entitlement")
  func throwsWithoutEntitlement() async {
    do {
      try await HealthKitService.shared.requestAuthorization()
      Issue.record("Expected error")
    } catch {
      #expect(error != nil)
    }
  }
}

#endif

struct MediaModelTests {

  @Test("MediaAttachment initializes")
  func mediaAttachmentInit() {
    let att = MediaAttachment(type: .photo)
    #expect(att.type == .photo)
  }

  @Test("MediaAttachment coding round-trip")
  func mediaAttachmentCoding() throws {
    let att = MediaAttachment(type: .audio, localURL: URL(string: "file:///tmp/test.m4a"), remoteURL: URL(string: "https://example.com/test.m4a"))
    let data = try JSONEncoder().encode(att)
    let decoded = try JSONDecoder().decode(MediaAttachment.self, from: data)
    #expect(decoded.type == .audio)
    #expect(decoded.localURL?.absoluteString == "file:///tmp/test.m4a")
    #expect(decoded.remoteURL?.absoluteString == "https://example.com/test.m4a")
  }
}

struct FacilityStatsTests {

  @Test("FacilityStatsDTO decodes")
  func statsDecoding() throws {
    let json = """
    {"falls_last_7d": 5, "open_alerts": 3, "avg_acknowledge_minutes": 12}
    """
    let data = json.data(using: .utf8)!
    let stats = try JSONDecoder().decode(FacilityStatsDTO.self, from: data)
    #expect(stats.falls_last_7d == 5)
    #expect(stats.open_alerts == 3)
    #expect(stats.avg_acknowledge_minutes == 12)
  }
}
