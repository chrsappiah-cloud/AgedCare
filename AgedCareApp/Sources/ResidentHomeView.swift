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
        alertsRepository: container.alertsRepository,
        residentsRepository: container.residentsRepository
      ),
      facilityId: facilityId,
      residentId: residentId
    )
    .onAppear {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
      SoundManager.shared.prepare()
    }
  }
}

struct ResidentHomeView: View {
  @ObservedObject var coordinator: MonitoringCoordinator
  @EnvironmentObject var container: DependencyContainer
  @EnvironmentObject var handoff: HandoffService
  @State private var showStaffConnected = false

  private let facilityId: UUID
  private let residentId: UUID

  init(coordinator: MonitoringCoordinator, facilityId: UUID, residentId: UUID) {
    self.coordinator = coordinator
    self.facilityId = facilityId
    self.residentId = residentId
  }

  var body: some View {
    VStack(spacing: 28) {
      connectionBanner
      monitoringStatusCard
      sosButton
      callStaffCard
      reassuranceSection
      Spacer()
    }
    .padding()
    .onAppear {
      coordinator.startMonitoring()
      handoff.startListening { action in handleHandoff(action) }
    }
    .sheet(isPresented: $showStaffConnected) {
      staffConnectedSheet
    }
  }

  private var connectionBanner: some View {
    HStack(spacing: 8) {
      Image(systemName: "applewatch.watchface")
        .font(.title3)
      Text("Connected to AgedCare")
        .font(.subheadline)
      Spacer()
      if WatchConnectivityService.shared.isReachable {
        Image(systemName: "applewatch.radiowaves.left.and.right")
          .foregroundColor(.green)
          .accessibilityLabel("Watch connected")
      }
    }
    .padding(12)
    .background(.ultraThinMaterial)
    .cornerRadius(12)
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
    .padding(.top, 4)
    .accessibilityLabel("SOS call for help")
    .accessibilityHint("Sends an emergency alert to all staff")
  }

  private var callStaffCard: some View {
    Button(action: { Task { await handoff.requestStaff(
      facilityId: facilityId.uuidString,
      residentId: residentId.uuidString,
      residentName: "Room \(residentId.uuidString.prefix(6))"
    )}}) {
      HStack(spacing: 12) {
        Image(systemName: "bell.and.waves.left.and.right.fill")
          .font(.title2)
        VStack(alignment: .leading, spacing: 2) {
          Text("Call a staff member")
            .font(.headline)
          Text("Notifies available staff to check on you")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding()
      .background(.thinMaterial)
      .cornerRadius(14)
    }
    .buttonStyle(.plain)
    .accessibilityHint("Sends a notification to request staff assistance")
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
    .padding(.top, 8)
  }

  private var staffConnectedSheet: some View {
    VStack(spacing: 24) {
      Image(systemName: "person.fill.checkmark")
        .font(.system(size: 60))
        .foregroundColor(.green)
      Text("Staff Member Connected")
        .font(.title.bold())
      Text("A staff member has taken over monitoring. Your device is now linked to their dashboard.")
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
      Button("OK") {
        showStaffConnected = false
        handoff.clearHandoff()
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(32)
  }

  private func triggerSOS() {
    SoundManager.shared.playSOS()
    WatchConnectivityService.shared.sendSOSAlert(facilityId: facilityId.uuidString, residentId: residentId.uuidString)
    Task {
      do {
        try await container.alertsRepository.createSOSAlert(facilityId: facilityId, residentId: residentId)
        coordinator.lastErrorMessage = nil
        let content = UNMutableNotificationContent()
        content.title = "SOS Sent"
        content.body = "Help has been requested. A staff member will respond shortly."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
      } catch {
        coordinator.lastErrorMessage = error.localizedDescription
      }
    }
  }

  private func handleHandoff(_ action: HandoffAction) {
    switch action {
    case .staffTakeover:
      showStaffConnected = true
      coordinator.stopMonitoring()
    default:
      break
    }
  }
}
