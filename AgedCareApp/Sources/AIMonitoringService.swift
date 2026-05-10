import Foundation
import UIKit
import AgedCareShared

@MainActor
final class AIMonitoringService: ObservableObject {
  static let shared = AIMonitoringService()

  private let baseURL: URL
  private let session = URLSession.shared

  @Published var recentInsights: [MediaAnalysisResult] = []
  @Published var activeSessions: [AudioMonitorSession] = []
  @Published var recentEvents: [AudioMonitorEvent] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private var pollTimer: Timer?

  init() {
    self.baseURL = AppHost.baseURL
  }

  // MARK: - Media Analysis

  func analyzeImage(_ image: UIImage, facilityId: String, residentId: String? = nil) async -> MediaAnalysisResult? {
    guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
    let b64 = data.base64EncodedString()
    return await analyzeMedia(b64, filename: "photo_\(UUID().uuidString.prefix(8)).jpg", mediaType: "photo", facilityId: facilityId, residentId: residentId)
  }

  func analyzeAudioBase64(_ b64: String, filename: String, facilityId: String, residentId: String? = nil, transcribedText: String? = nil) async -> MediaAnalysisResult? {
    return await analyzeMedia(b64, filename: filename, mediaType: "audio", facilityId: facilityId, residentId: residentId, transcribedText: transcribedText)
  }

  private func analyzeMedia(_ b64: String, filename: String, mediaType: String, facilityId: String, residentId: String? = nil, transcribedText: String? = nil) async -> MediaAnalysisResult? {
    var req = URLRequest(url: baseURL.appendingPathComponent("/ai/analyze/media"))
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    var body: [String: Any] = [
      "data_base64": b64,
      "filename": filename,
      "media_type": mediaType,
      "facility_id": facilityId,
    ]
    if let rid = residentId { body["resident_id"] = rid }
    if let tt = transcribedText { body["transcribed_text"] = tt }
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)

    do {
      let (data, _) = try await session.data(for: req)
      let decoder = JSONDecoder()
      return try decoder.decode(MediaAnalysisResult.self, from: data)
    } catch {
      errorMessage = error.localizedDescription
      return nil
    }
  }

  // MARK: - Insights Fetching

  func fetchInsights(facilityId: String, limit: Int = 20) async {
    isLoading = true
    errorMessage = nil
    var req = URLRequest(url: baseURL.appendingPathComponent("/ai/insights"))
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["facility_id": facilityId, "limit": limit]
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)

    do {
      let (data, _) = try await session.data(for: req)
      let decoder = JSONDecoder()
      recentInsights = try decoder.decode([MediaAnalysisResult].self, from: data)
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  // MARK: - Audio Monitoring Sessions

  func startMonitoring(facilityId: String, residentId: String? = nil, staffId: String? = nil) async -> String? {
    var req = URLRequest(url: baseURL.appendingPathComponent("/ai/monitor/start"))
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    var body: [String: Any] = ["facility_id": facilityId]
    if let rid = residentId { body["resident_id"] = rid }
    if let sid = staffId { body["started_by"] = sid }
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)

    do {
      let (data, _) = try await session.data(for: req)
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
      return json?["session_id"] as? String
    } catch {
      errorMessage = error.localizedDescription
      return nil
    }
  }

  func stopMonitoring(sessionId: String) async {
    guard let url = URL(string: "\(baseURL)/ai/monitor/\(sessionId)/stop") else { return }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    _ = try? await session.data(for: req)
  }

  func reportEvent(sessionId: String, event: AIEventReport) async {
    guard let url = URL(string: "\(baseURL)/ai/monitor/\(sessionId)/event") else { return }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONEncoder().encode(event)
    _ = try? await session.data(for: req)
  }

  func fetchSessions(facilityId: String, limit: Int = 10) async {
    var req = URLRequest(url: baseURL.appendingPathComponent("/ai/sessions"))
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["facility_id": facilityId, "limit": limit]
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)

    do {
      let (data, _) = try await session.data(for: req)
      let decoder = JSONDecoder()
      activeSessions = try decoder.decode([AudioMonitorSession].self, from: data)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func fetchRecentEvents(facilityId: String, hours: Int = 24) async {
    var req = URLRequest(url: baseURL.appendingPathComponent("/ai/events/recent"))
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["facility_id": facilityId, "hours": hours]
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)

    do {
      let (data, _) = try await session.data(for: req)
      let decoder = JSONDecoder()
      recentEvents = try decoder.decode([AudioMonitorEvent].self, from: data)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  // MARK: - Polling

  func startPolling(facilityId: String, interval: TimeInterval = 10) {
    stopPolling()
    pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
      Task { [weak self] in
        await self?.fetchRecentEvents(facilityId: facilityId)
      }
    }
  }

  func stopPolling() {
    pollTimer?.invalidate()
    pollTimer = nil
  }

  deinit {
    pollTimer?.invalidate()
    pollTimer = nil
  }
}
