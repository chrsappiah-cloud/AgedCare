import SwiftUI

struct StaffShellView: View {
  let staff: StaffUserModel
  let session: SessionViewModel
  @EnvironmentObject var container: DependencyContainer
  @EnvironmentObject var handoff: HandoffService
  @State private var showAIMonitor = false
  @State private var showHandoffBanner = false

  var body: some View {
    TabView {
      AlertsHomeView(staff: staff)
        .tabItem {
          Label("Alerts", systemImage: "bell.badge.fill")
        }
        .accessibilityLabel("Alerts tab")

      ResidentsHomeView(staff: staff)
        .tabItem {
          Label("Residents", systemImage: "person.3.fill")
        }
        .accessibilityLabel("Residents tab")

      MediaInsightsDashboardView(staff: staff)
        .tabItem {
          Label("AI Monitor", systemImage: "waveform.eye")
        }
        .accessibilityLabel("AI Monitoring tab")
        .badge(aiBadgeCount + handoffBadgeCount)

      InsightsView(staff: staff)
        .tabItem {
          Label("Insights", systemImage: "chart.bar.doc.horizontal.fill")
        }
        .accessibilityLabel("Insights tab")

      SettingsView(staff: staff, session: session)
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
        .accessibilityLabel("Settings tab")
    }
    .tint(AppTheme.emeraldGreen)
    .accessibilityLabel("Main tabs")
    .overlay(alignment: .top) { handoffBanner }
    .onChange(of: handoff.pendingHandoff) { _, newValue in
      showHandoffBanner = newValue != nil
    }
    .sheet(isPresented: $showHandoffBanner) {
      if case .requestStaff(let fid, let rid, let name) = handoff.pendingHandoff {
        HandoffRequestView(
          facilityId: fid, residentId: rid, residentName: name,
          staff: staff, session: session, handoff: handoff
        )
      }
    }
  }

  @ViewBuilder
  private var handoffBanner: some View {
    if case .requestStaff(_, _, let name) = handoff.pendingHandoff {
      Button(action: { showHandoffBanner = true }) {
        HStack(spacing: 8) {
          Image(systemName: "bell.and.waves.left.and.right.fill")
            .font(.subheadline)
          Text("\(name) needs assistance")
            .font(.subheadline.bold())
          Spacer()
          Image(systemName: "chevron.right")
            .font(.caption)
        }
        .padding(12)
        .background(AppTheme.gradientEmeraldRed)
        .foregroundColor(AppTheme.textOnPrimary)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 6)
      }
      .transition(.move(edge: .top).combined(with: .opacity))
      .animation(.spring, value: showHandoffBanner)
      .accessibilityLabel("\(name) has requested staff assistance. Tap to respond.")
    }
  }

  private var aiBadgeCount: Int {
    AIMonitoringService.shared.recentEvents.filter { !$0.acknowledged }.count
  }

  private var handoffBadgeCount: Int {
    handoff.pendingHandoff != nil ? 1 : 0
  }
}

struct HandoffRequestView: View {
  let facilityId: String
  let residentId: String
  let residentName: String
  let staff: StaffUserModel
  let session: SessionViewModel
  @ObservedObject var handoff: HandoffService
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      Image(systemName: "bell.and.waves.left.and.right.fill")
        .font(.system(size: 60))
        .foregroundColor(AppTheme.emeraldRed)

      Text("Assistance Requested")
        .font(.title.bold())
        .foregroundColor(AppTheme.textPrimary)

      VStack(spacing: 8) {
        Label(residentName, systemImage: "person.fill")
          .font(.headline)
          .foregroundColor(AppTheme.textPrimary)
        Label("Facility: \(facilityId.prefix(8))", systemImage: "building.2.fill")
          .font(.subheadline)
          .foregroundColor(AppTheme.textSecondary)
      }

      Text("This resident has requested a staff member to check on them.")
        .multilineTextAlignment(.center)
        .foregroundColor(AppTheme.textSecondary)

      Spacer()

      VStack(spacing: 12) {
        Button(action: {
          Task {
            await handoff.staffTakeover(
              staffId: staff.id.uuidString,
              staffName: staff.displayName ?? staff.role,
              facilityId: facilityId,
              session: session
            )
          }
          dismiss()
        }) {
          Label("Respond to \(residentName)", systemImage: "person.fill.checkmark")
            .primaryButtonStyle()
        }
        .accessibilityHint("Marks this request as handled and notifies the resident")

        Button(role: .cancel) {
          handoff.clearHandoff()
          dismiss()
        } label: {
          Text("Dismiss")
            .font(.subheadline)
            .foregroundColor(AppTheme.textSecondary)
        }
      }
    }
    .padding(32)
    .background(AppTheme.background)
  }
}
