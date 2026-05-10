import SwiftUI
import AgedCareShared
import AudioToolbox
import UserNotifications

struct ResidentShellView: View {
  let facilityId: UUID
  let residentId: UUID
  @EnvironmentObject var container: DependencyContainer

  var body: some View {
    let fallService = container.makeFallService(facilityId: facilityId, residentId: residentId)
    ResidentHomeView(
      coordinator: MonitoringCoordinator(
        fallService: fallService,
        facilityId: facilityId,
        residentId: residentId,
        alertsRepository: container.alertsRepository
      ),
      facilityId: facilityId,
      residentId: residentId
    )
    .onAppear {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
  }
}

struct ResidentHomeView: View {
  @ObservedObject var coordinator: MonitoringCoordinator
  @EnvironmentObject var container: DependencyContainer

  private let facilityId: UUID
  private let residentId: UUID

  init(coordinator: MonitoringCoordinator, facilityId: UUID, residentId: UUID) {
    self.coordinator = coordinator
    self.facilityId = facilityId
    self.residentId = residentId
  }

  var body: some View {
    VStack(spacing: 32) {
      Text("You are being monitored")
        .font(.system(size: 28, weight: .semibold))
        .multilineTextAlignment(.center)

      monitoringStatusCard
      sosButton
      reassuranceSection

      Spacer()
    }
    .padding()
    .onAppear { coordinator.startMonitoring() }
  }

  private var monitoringStatusCard: some View {
    VStack(spacing: 12) {
      HStack {
        Circle()
          .fill(coordinator.monitoringEnabled ? Color.green : Color.red)
          .frame(width: 16, height: 16)
        Text(coordinator.monitoringEnabled ? "Monitoring active" : "Monitoring paused")
          .font(.title3)
        Spacer()
      }
      if let event = coordinator.lastEvent {
        Text("We noticed a strong movement at \(event.timestamp.formatted(date: .omitted, time: .shortened)). A staff member will check on you if needed.")
          .font(.body)
          .foregroundColor(.secondary)
      } else {
        Text("If you feel unwell or have a fall, press the button below.")
          .font(.body)
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .background(.thinMaterial)
    .cornerRadius(18)
  }

  private var sosButton: some View {
    Button(action: triggerSOS) {
      ZStack {
        Circle()
          .fill(Color.red)
          .frame(width: 160, height: 160)
          .shadow(radius: 10)
        Text("I need\nhelp")
          .font(.system(size: 32, weight: .bold))
          .multilineTextAlignment(.center)
          .foregroundColor(.white)
      }
    }
    .padding(.top, 8)
  }

  private var reassuranceSection: some View {
    VStack(spacing: 8) {
      Text("A nurse will be alerted if we detect a possible fall.")
        .font(.footnote)
        .foregroundColor(.secondary)
      if let error = coordinator.lastErrorMessage {
        Text("Note: there was a problem sending information to the nurses. They may not see updates right away.")
          .font(.footnote)
          .foregroundColor(.orange)
      }
    }
    .padding(.top, 16)
  }

  private func triggerSOS() {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    Task {
      do {
        try await container.alertsRepository.createSOSAlert(facilityId: facilityId, residentId: residentId)
        coordinator.lastErrorMessage = nil
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "SOS Sent"
        content.body = "Help has been requested. A staff member will respond shortly."
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
      } catch {
        coordinator.lastErrorMessage = error.localizedDescription
      }
    }
  }
}
