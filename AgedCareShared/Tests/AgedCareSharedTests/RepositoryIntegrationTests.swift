import Testing
import Foundation
@testable import AgedCareShared

// MARK: - Mock URL Protocol

final class MockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard let handler = Self.requestHandler else {
      fatalError("No handler set")
    }
    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

// MARK: - Helpers

func extractBody(_ request: URLRequest) throws -> Data {
  if let body = request.httpBody { return body }
  guard let stream = request.httpBodyStream else {
    throw URLError(.badServerResponse)
  }
  stream.open()
  defer { stream.close() }
  var data = Data()
  let bufferSize = 1024
  let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
  defer { buffer.deallocate() }
  while stream.hasBytesAvailable {
    let read = stream.read(buffer, maxLength: bufferSize)
    guard read >= 0 else { throw URLError(.cannotParseResponse) }
    data.append(buffer, count: read)
  }
  return data
}

// MARK: - Testable Supabase Client

extension SupabaseClient {
  static func makeForTesting() -> SupabaseClient {
    let config = SupabaseConfig(baseURL: URL(string: "https://test.supabase.co")!, apiKey: "test-key")
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: sessionConfig)
    return SupabaseClient(config: config, session: session, accessTokenProvider: { "test-token" })
  }
}

// MARK: - Integration Tests

@Suite("Repository Integration Tests", .serialized)
struct RepositoryIntegrationTests {

  // MARK: - AlertsRepository

  @Test("AlertsRepository getOpenAlerts decodes response")
  func getOpenAlerts() async throws {
    let json = """
    [{"id": 1, "resident_id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F", "type": "fall", "status": "open", "priority": 3, "created_at": "2026-05-10T00:00:00Z"}]
    """
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, json.data(using: .utf8)!)
    }

    let client = SupabaseClient.makeForTesting()
    let repo = AlertsRepository(supabase: client)
    let alerts = try await repo.getOpenAlerts(facilityId: UUID())

    #expect(alerts.count == 1)
    #expect(alerts[0].id == 1)
    #expect(alerts[0].type == "fall")
    #expect(alerts[0].priority == 3)
  }

  @Test("AlertsRepository createFallAlert encodes request and decodes response")
  func createFallAlert() async throws {
    let json = "{\"alert_id\": 42}"
    MockURLProtocol.requestHandler = { request in
      let bodyData = try extractBody(request)
      let body = try JSONSerialization.jsonObject(with: bodyData) as! [String: Any]
      #expect(body["p_facility_id"] != nil)
      #expect(body["p_resident_id"] != nil)
      #expect(body["p_priority"] as? Int == 2)
      #expect(request.url?.absoluteString.contains("create_fall_alert") == true)
      #expect(request.value(forHTTPHeaderField: "apikey") == "test-key")
      #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")

      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, json.data(using: .utf8)!)
    }

    let client = SupabaseClient.makeForTesting()
    let repo = AlertsRepository(supabase: client)
    let alertId = try await repo.createFallAlert(facilityId: UUID(), residentId: UUID(), priority: 2)

    #expect(alertId == 42)
  }

  @Test("AlertsRepository createSOSAlert returns alert id")
  func createSOSAlert() async throws {
    let json = "{\"alert_id\": 99}"
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, json.data(using: .utf8)!)
    }

    let client = SupabaseClient.makeForTesting()
    let repo = AlertsRepository(supabase: client)
    let alertId = try await repo.createSOSAlert(facilityId: UUID(), residentId: UUID())

    #expect(alertId == 99)
  }

  @Test("AlertsRepository acknowledgeAlert calls RPC with correct parameters")
  func acknowledgeAlert() async throws {
    MockURLProtocol.requestHandler = { request in
      let bodyData = try extractBody(request)
      let body = try JSONSerialization.jsonObject(with: bodyData) as! [String: Any]
      #expect(body["p_alert_id"] as? Int64 == 1)
      #expect(body["p_staff_id"] != nil)
      #expect(request.url?.absoluteString.contains("acknowledge_alert") == true)
      let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
      return (response, Data())
    }

    let client = SupabaseClient.makeForTesting()
    let repo = AlertsRepository(supabase: client)
    try await repo.acknowledgeAlert(alertId: 1, staffId: UUID())
  }

  @Test("AlertsRepository closeAlert calls RPC with notes")
  func closeAlert() async throws {
    MockURLProtocol.requestHandler = { request in
      let bodyData = try extractBody(request)
      let body = try JSONSerialization.jsonObject(with: bodyData) as! [String: Any]
      #expect(body["p_alert_id"] as? Int64 == 2)
      #expect(body["p_notes"] as? String == "Test note")
      let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
      return (response, Data())
    }

    let client = SupabaseClient.makeForTesting()
    let repo = AlertsRepository(supabase: client)
    try await repo.closeAlert(alertId: 2, notes: "Test note")
  }

  @Test("AlertsRepository throws on HTTP error")
  func httpError() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
      return (response, Data())
    }

    let client = SupabaseClient.makeForTesting()
    let repo = AlertsRepository(supabase: client)

    do {
      _ = try await repo.getOpenAlerts(facilityId: UUID())
      #expect(Bool(false), "Expected error but got success")
    } catch let SupabaseError.httpError(code, _) {
      #expect(code == 500)
    }
  }

  // MARK: - ResidentsRepository

  @Test("ResidentsRepository getResidents decodes response")
  func getResidents() async throws {
    let json = """
    [{"id": "22222222-2222-4222-8222-222222222222", "facility_id": "11111111-1111-4111-8111-111111111111", "name": "John Smith", "risk_level": "high", "date_of_birth": null}]
    """
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, json.data(using: .utf8)!)
    }

    let client = SupabaseClient.makeForTesting()
    let repo = ResidentsRepository(supabase: client)
    let residents = try await repo.getResidents(facilityId: UUID())

    #expect(residents.count == 1)
    #expect(residents[0].name == "John Smith")
    #expect(residents[0].risk_level == "high")
  }

  @Test("ResidentsRepository getFallCount returns integer")
  func getFallCount() async throws {
    let json = "5"
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, json.data(using: .utf8)!)
    }

    let client = SupabaseClient.makeForTesting()
    let repo = ResidentsRepository(supabase: client)
    let count = try await repo.getFallCount(residentId: UUID(), days: 7)

    #expect(count == 5)
  }

  @Test("ResidentsRepository getTimeline decodes response")
  func getTimeline() async throws {
    let json = """
    [{"kind": "fall", "ts": "2026-05-08T00:00:00Z", "summary": "Fall detected"}, {"kind": "vital", "ts": "2026-05-10T00:00:00Z", "summary": "heartRate: 72"}]
    """
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, json.data(using: .utf8)!)
    }

    let client = SupabaseClient.makeForTesting()
    let repo = ResidentsRepository(supabase: client)
    let entries = try await repo.getTimeline(residentId: UUID())

    #expect(entries.count == 2)
    #expect(entries[0].kind == "fall")
    #expect(entries[1].kind == "vital")
    #expect(entries[1].summary == "heartRate: 72")
  }

  // MARK: - FacilityRepository

  @Test("FacilityRepository getStats decodes response")
  func getStats() async throws {
    let json = """
    {"falls_last_7d": 3, "open_alerts": 5, "avg_acknowledge_minutes": 15}
    """
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, json.data(using: .utf8)!)
    }

    let client = SupabaseClient.makeForTesting()
    let repo = FacilityRepository(supabase: client)
    let stats = try await repo.getStats(facilityId: UUID())

    #expect(stats.falls_last_7d == 3)
    #expect(stats.open_alerts == 5)
    #expect(stats.avg_acknowledge_minutes == 15)
  }

  // MARK: - End-to-End Flow: Alert Lifecycle

  @Test("End-to-end: Full alert lifecycle (create → list → acknowledge → close)")
  func fullAlertLifecycle() async throws {
    var callCount = 0

    MockURLProtocol.requestHandler = { request in
      callCount += 1
      let url = request.url!.absoluteString

      switch callCount {
      case 1:
        // createFallAlert
        #expect(url.contains("create_fall_alert"))
        return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, "{\"alert_id\": 10}".data(using: .utf8)!)
      case 2:
        // getOpenAlerts
        #expect(url.contains("get_open_alerts_for_facility"))
        let json = """
        [{"id": 10, "resident_id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F", "type": "fall", "status": "open", "priority": 3, "created_at": "2026-05-10T00:00:00Z"}]
        """
        return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, json.data(using: .utf8)!)
      case 3:
        // acknowledgeAlert
        #expect(url.contains("acknowledge_alert"))
        return (HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!, Data())
      case 4:
        // getOpenAlerts (after ack)
        let json = """
        [{"id": 10, "resident_id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F", "type": "fall", "status": "ack", "priority": 3, "created_at": "2026-05-10T00:00:00Z"}]
        """
        return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, json.data(using: .utf8)!)
      case 5:
        // closeAlert
        #expect(url.contains("close_alert"))
        return (HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!, Data())
      default:
        #expect(Bool(false), "Unexpected call #\(callCount)")
        return (HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!, Data())
      }
    }

    let client = SupabaseClient.makeForTesting()
    let repo = AlertsRepository(supabase: client)
    let facilityId = UUID()
    let residentId = UUID()
    let staffId = UUID()

    // Step 1: Create fall alert
    let alertId = try await repo.createFallAlert(facilityId: facilityId, residentId: residentId, priority: 3)
    #expect(alertId == 10)

    // Step 2: List open alerts
    var alerts = try await repo.getOpenAlerts(facilityId: facilityId)
    #expect(alerts.count == 1)
    #expect(alerts[0].status == "open")

    // Step 3: Acknowledge
    try await repo.acknowledgeAlert(alertId: alertId, staffId: staffId)

    // Step 4: Verify alert was acknowledged
    alerts = try await repo.getOpenAlerts(facilityId: facilityId)
    #expect(alerts[0].status == "ack")

    // Step 5: Close alert
    try await repo.closeAlert(alertId: alertId, notes: "Resolved")

    #expect(callCount == 5, "Expected 5 API calls")
  }
}
