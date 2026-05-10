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
    ScrollView {
      VStack(spacing: 28) {
        connectionBanner
        monitoringStatusCard
        sosButton
        callStaffCard
        reassuranceSection
      }
      .padding()
    }
    .background(AppTheme.gradientDiamond.ignoresSafeArea())
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
        .foregroundColor(AppTheme.darkChocolate)
      Text("Connected to AgedCare")
        .font(.subheadline)
        .foregroundColor(AppTheme.textPrimary)
      Spacer()
      if WatchConnectivityService.shared.isReachable {
        Image(systemName: "applewatch.radiowaves.left.and.right")
          .foregroundColor(AppTheme.emeraldGreen)
          .accessibilityLabel("Watch connected")
      }
    }
    .padding(12)
    .background(AppTheme.surface)
    .cornerRadius(12)
    .shadow(color: AppTheme.darkChocolate.opacity(0.06), radius: 4, x: 0, y: 2)
  }

  private var monitoringStatusCard: some View {
    VStack(spacing: 12) {
      HStack {
        Circle()
          .fill(coordinator.monitoringEnabled ? AppTheme.emeraldGreen : AppTheme.emeraldRed)
          .frame(width: 16, height: 16)
        Text(coordinator.monitoringEnabled ? "Monitoring active" : "Monitoring paused")
          .font(.title3.bold())
          .foregroundColor(AppTheme.textPrimary)
        Spacer()
      }
      if let event = coordinator.lastEvent {
        Text("We noticed a strong movement at \(event.timestamp.formatted(date: .omitted, time: .shortened)). A staff member will check on you if needed.")
          .font(.body)
          .foregroundColor(AppTheme.textSecondary)
      } else {
        Text("If you feel unwell or have a fall, press the button below.")
          .font(.body)
          .foregroundColor(AppTheme.textSecondary)
      }
    }
    .padding()
    .cardStyle()
  }

  private var sosButton: some View {
    Button(action: triggerSOS) {
      ZStack {
        Circle()
          .fill(AppTheme.gradientEmeraldRed)
          .frame(width: 160, height: 160)
          .shadow(color: AppTheme.emeraldRed.opacity(0.4), radius: 14, x: 0, y: 6)
        VStack(spacing: 2) {
          Image(systemName: "exclamationmark.circle.fill")
            .font(.title)
          Text("I need\nhelp")
            .font(.system(size: 28, weight: .bold))
            .multilineTextAlignment(.center)
        }
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
          .foregroundColor(AppTheme.emeraldGreen)
        VStack(alignment: .leading, spacing: 2) {
          Text("Call a staff member")
            .font(.headline)
            .foregroundColor(AppTheme.textPrimary)
          Text("Notifies available staff to check on you")
            .font(.caption)
            .foregroundColor(AppTheme.textSecondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(AppTheme.textSecondary)
      }
      .padding()
      .cardStyle()
    }
    .buttonStyle(.plain)
    .accessibilityHint("Sends a notification to request staff assistance")
  }

  private var reassuranceSection: some View {
    VStack(spacing: 8) {
      Text("A nurse will be alerted if we detect a possible fall.")
        .font(.footnote)
        .foregroundColor(AppTheme.textSecondary)
      if coordinator.lastErrorMessage != nil {
        HStack(spacing: 6) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.caption)
          Text("There was a problem sending information to the nurses. They may not see updates right away.")
            .font(.footnote)
        }
        .foregroundColor(AppTheme.warning)
      }
    }
    .padding(.top, 8)
  }

  private var staffConnectedSheet: some View {
    VStack(spacing: 24) {
      Spacer()
      Image(systemName: "person.fill.checkmark")
        .font(.system(size: 60))
        .foregroundColor(AppTheme.emeraldGreen)
      Text("Staff Member Connected")
        .font(.title.bold())
        .foregroundColor(AppTheme.textPrimary)
      Text("A staff member has taken over monitoring. Your device is now linked to their dashboard.")
        .multilineTextAlignment(.center)
        .foregroundColor(AppTheme.textSecondary)
      Spacer()
      Button(action: {
        showStaffConnected = false
        handoff.clearHandoff()
      }) {
        Text("OK")
          .primaryButtonStyle()
          .frame(maxWidth: 200)
      }
    }
    .padding(32)
    .background(AppTheme.background)
  }

  private func triggerSOS() {
    SoundManager.shared.playSOS()
    WatchConnectivityService.shared.sendSOSAlert(facilityId: facilityId.uuidString, residentId: residentId.uuidString)
    Task {
      do {
        let _ = try await container.alertsRepository.createSOSAlert(facilityId: facilityId, residentId: residentId)
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
