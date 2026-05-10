import Foundation
import AgedCareShared
import UserNotifications

@MainActor
final class MonitoringCoordinator: ObservableObject {
  @Published var monitoringEnabled = false
  @Published var healthKitAuthorized = false
  @Published var lastEvent: FallDetectionEvent?
  @Published var lastErrorMessage: String?
  @Published var latestHeartRate: String?
  @Published var latestBloodOxygen: String?
  @Published var hkAuthError: String?

  private let fallService: FallService
  private let facilityId: UUID
  private let residentId: UUID
  private let alertsRepository: AlertsRepositoryProtocol
  private let residentsRepository: ResidentsRepository
  private var healthTask: Task<Void, Never>?
  private var vitalEventTask: Task<Void, Never>?

  init(fallService: FallService, facilityId: UUID, residentId: UUID, alertsRepository: AlertsRepositoryProtocol, residentsRepository: ResidentsRepository) {
    self.fallService = fallService
    self.facilityId = facilityId
    self.residentId = residentId
    self.alertsRepository = alertsRepository
    self.residentsRepository = residentsRepository
    self.fallService.delegate = self
  }

  func startMonitoring() {
    monitoringEnabled = true
    fallService.start()
    authorizeAndStartHealthKit()
    subscribeToCloudKitAlerts()
  }

  func stopMonitoring() {
    monitoringEnabled = false
    fallService.stop()
    healthTask?.cancel()
    healthTask = nil
    vitalEventTask?.cancel()
    vitalEventTask = nil
  }

  private func authorizeAndStartHealthKit() {
    guard HealthKitService.shared.isAvailable else {
      hkAuthError = "HealthKit not available on this device"
      return
    }

    Task {
      do {
        try await HealthKitService.shared.requestAuthorization()
        healthKitAuthorized = true
        hkAuthError = nil
        startHealthKitMonitoring()
      } catch {
        hkAuthError = "HealthKit auth failed: \(error.localizedDescription)"
        healthKitAuthorized = false
      }
    }
  }

  private func startHealthKitMonitoring() {
    guard HealthKitService.shared.isAvailable, healthKitAuthorized else { return }

    healthTask = Task { [weak self] in
      do {
        let stream = HealthKitService.shared.startHeartRateMonitoring(interval: 30)
        for try await reading in stream {
          guard let self = self, self.monitoringEnabled else { break }
          self.latestHeartRate = "\(Int(reading.value)) bpm"

          if let alert = HealthKitService.shared.detectAbnormalVitals(reading: reading) {
            await self.handleVitalAlert(alert)
          }

          await self.recordVitalReading(reading)
        }
      } catch {
        print("[MonitoringCoordinator] HealthKit monitoring error: \(error)")
      }
    }
  }

  private func recordVitalReading(_ reading: VitalReading) async {
    #if canImport(HealthKit)
    let metric: String
    let value: Double
    switch reading.type {
    case .heartRate:
      metric = "heart_rate"
      value = reading.value
    case .oxygenSaturation:
      metric = "blood_oxygen"
      value = reading.value
    default:
      return
    }
    #else
    let metric = reading.type
    let value = reading.value
    #endif

    do {
      try await residentsRepository.recordVitalEvent(
        facilityId: facilityId,
        residentId: residentId,
        metric: metric,
        value: value,
        timestamp: reading.timestamp
      )
    } catch {
      print("[MonitoringCoordinator] Failed to record vital: \(error)")
    }
  }

  private func handleVitalAlert(_ alert: VitalAlert) async {
    let title: String
    let body: String

    switch alert {
    case .highHeartRate(let reading):
      title = "High Heart Rate"
      body = "\(Int(reading.value)) bpm — above threshold"
    case .lowHeartRate(let reading):
      title = "Low Heart Rate"
      body = "\(Int(reading.value)) bpm — below threshold"
    case .lowBloodOxygen(let reading):
      title = "Low Blood Oxygen"
      body = "\(Int(reading.value * 100))% — below 90% threshold"
    case .fallImpact:
      title = "Fall Impact Detected"
      body = "Motion sensors detected a potential fall"
      await triggerExternalAlert(type: "fall", priority: 3)
    }

    postLocalNotification(title: title, body: body)
  }

  private func triggerExternalAlert(type: String, priority: Int) async {
    do {
      try await alertsRepository.createFallAlert(facilityId: facilityId, residentId: residentId, priority: priority)
    } catch {
      lastErrorMessage = "Alert creation failed: \(error.localizedDescription)"
    }
  }

  private func subscribeToCloudKitAlerts() {
    #if canImport(CloudKit)
    guard let sync = CloudKitAlertSync.shared else { return }
    sync.alertUpdateHandler = { [weak self] alert, reason in
      Task { @MainActor in
        self?.postLocalNotification(
          title: "Alert \(reason == .recordCreated ? "" : "Updated")",
          body: "\(alert.typeDisplay) — Priority \(alert.priority)"
        )
      }
    }
    #endif
  }

  private func postLocalNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
  }
}

extension MonitoringCoordinator: FallServiceDelegate {
  func fallServiceDidTriggerPossibleFall(_ service: FallService, event: FallDetectionEvent) {
    lastEvent = event
    postLocalNotification(
      title: "Possible Fall Detected",
      body: "Staff have been notified."
    )
    Task { await triggerExternalAlert(type: "fall", priority: 3) }
  }

  func fallService(_ service: FallService, didFailWith error: Error) {
    lastErrorMessage = error.localizedDescription
  }
}
