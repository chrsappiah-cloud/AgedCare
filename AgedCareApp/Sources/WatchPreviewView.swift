import SwiftUI
import AgedCareShared

struct WatchPreviewView: View {
  @StateObject private var vm = WatchPreviewViewModel()
  @State private var selectedTab = 0
  @State private var showSOSConfirmation = false

  var body: some View {
    VStack(spacing: 0) {
      watchHeader
      watchScreen
        .frame(width: watchSize.width, height: watchSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 44))
        .overlay(
          RoundedRectangle(cornerRadius: 44)
            .stroke(AppTheme.diamondSilver, lineWidth: 2)
        )
        .shadow(color: AppTheme.darkChocolate.opacity(0.2), radius: 12)
      watchControls
    }
    .padding()
    .background(AppTheme.background)
    .navigationTitle("Watch Preview")
    .accessibilityLabel("Apple Watch Preview")
    .accessibilityHint("Simulates an Apple Watch interface for testing")
  }

  private let watchSize = CGSize(width: 180, height: 215)

  private var watchHeader: some View {
    HStack {
      Circle()
        .fill(vm.isWatchReachable ? AppTheme.emeraldGreen : AppTheme.emeraldRed)
        .frame(width: 6, height: 6)
      Text(vm.isWatchReachable ? "Connected" : "Disconnected")
        .font(.caption2)
        .foregroundColor(AppTheme.textSecondary)
      Spacer()
      Text(formattedTime)
        .font(.caption2)
        .foregroundColor(AppTheme.textSecondary)
        .monospacedDigit()
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .frame(width: watchSize.width)
    .background(AppTheme.darkChocolateBg.opacity(0.05))
    .cornerRadius(8)
  }

  private var watchScreen: some View {
    TabView(selection: $selectedTab) {
      watchStatusView.tag(0)
      watchAlertsView.tag(1)
      watchSOSView.tag(2)
    }
    .tabViewStyle(.page)
    .background(AppTheme.darkChocolateBg)
  }

  private var watchStatusView: some View {
    ScrollView {
      VStack(spacing: 8) {
        Image(systemName: vm.isMonitoringActive ? "heart.circle.fill" : "heart.slash")
          .font(.title2)
          .foregroundColor(vm.isMonitoringActive ? AppTheme.emeraldGreen : .gray)

        Text(vm.statusText)
          .font(.caption.bold())
          .foregroundColor(AppTheme.diamondSparkle)

        Divider().background(AppTheme.diamondSilver.opacity(0.3))

        Label {
          Text("\(vm.heartRate) bpm")
            .font(.caption.bold())
            .foregroundColor(AppTheme.diamondSparkle)
        } icon: {
          Image(systemName: "heart.fill").foregroundColor(AppTheme.emeraldRed).font(.caption)
        }

        Label {
          Text("\(vm.bloodOxygen) SpO2")
            .font(.caption.bold())
            .foregroundColor(AppTheme.diamondSparkle)
        } icon: {
          Image(systemName: "drop.fill").foregroundColor(AppTheme.emeraldGreen).font(.caption)
        }

        Text("Updated \(vm.lastSync.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 8))
          .foregroundColor(AppTheme.diamondSilver)
      }
      .padding(8)
    }
    .background(AppTheme.darkChocolateBg)
  }

  private var watchAlertsView: some View {
    List {
      if vm.alerts.isEmpty {
        Text("No active alerts")
          .font(.caption2)
          .foregroundColor(AppTheme.diamondSilver)
      }
      ForEach(vm.alerts) { alert in
        HStack(spacing: 4) {
          Circle()
            .fill(alert.priority > 2 ? AppTheme.emeraldRed : AppTheme.warning)
            .frame(width: 6, height: 6)
          Text(alert.summary)
            .font(.system(size: 9))
            .foregroundColor(AppTheme.diamondSparkle)
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(AppTheme.darkChocolateBg)
  }

  private var watchSOSView: some View {
    VStack(spacing: 10) {
      Spacer()
      Button(action: {
        vm.sendSOS()
        showSOSConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          showSOSConfirmation = false
        }
      }) {
        ZStack {
          Circle()
            .fill(AppTheme.emeraldRed)
            .frame(width: 70, height: 70)
            .shadow(color: AppTheme.emeraldRed.opacity(0.4), radius: 8)
          Text("SOS")
            .font(.caption.bold())
            .foregroundColor(.white)
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Send SOS alert")
      .accessibilityHint("Sends an emergency alert from the watch")

      if showSOSConfirmation {
        Text("Alert sent!")
          .font(.system(size: 9))
          .foregroundColor(AppTheme.emeraldGreen)
          .transition(.opacity)
      } else {
        Text("Emergency alert")
          .font(.system(size: 8))
          .foregroundColor(AppTheme.diamondSilver)
      }
      Spacer()
    }
    .background(AppTheme.darkChocolateBg)
  }

  private var watchControls: some View {
    HStack(spacing: 16) {
      Button(action: { selectedTab = 0 }) {
        Label("Status", systemImage: "heart.fill")
          .font(.caption2)
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.bordered)
      .tint(selectedTab == 0 ? AppTheme.emeraldGreen : .gray)

      Button(action: { selectedTab = 1 }) {
        Label("Alerts", systemImage: "bell.fill")
          .font(.caption2)
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.bordered)
      .tint(selectedTab == 1 ? AppTheme.emeraldGreen : .gray)

      Button(action: { selectedTab = 2 }) {
        Label("SOS", systemImage: "exclamationmark.triangle.fill")
          .font(.caption2)
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.bordered)
      .tint(selectedTab == 2 ? AppTheme.emeraldGreen : .gray)

      Spacer()

      Button(action: vm.simulateVitalUpdate) {
        Image(systemName: "arrow.triangle.2.circlepath")
          .font(.caption2)
      }
      .buttonStyle(.bordered)
      .tint(AppTheme.emeraldGreen)
      .accessibilityLabel("Simulate vital update")

      Button(action: vm.simulateAlert) {
        Image(systemName: "bell.badge")
          .font(.caption2)
      }
      .buttonStyle(.bordered)
      .tint(AppTheme.warning)
      .accessibilityLabel("Simulate test alert")
    }
    .padding(.top, 8)
  }

  private var formattedTime: String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f.string(from: Date())
  }
}

@MainActor
final class WatchPreviewViewModel: ObservableObject {
  @Published var heartRate = "--"
  @Published var bloodOxygen = "--"
  @Published var statusText = "Disconnected"
  @Published var isMonitoringActive = false
  @Published var isWatchReachable = false
  @Published var lastSync = Date()
  @Published var alerts: [PreviewAlert] = []

  struct PreviewAlert: Identifiable, Codable {
    let id: UUID
    let summary: String
    let priority: Int
    init(id: UUID = UUID(), summary: String, priority: Int) {
      self.id = id
      self.summary = summary
      self.priority = priority
    }
  }

  init() {
    isWatchReachable = WatchConnectivityService.shared.isReachable
    Task { @MainActor [weak self] in
      for await _ in NotificationCenter.default.notifications(named: .init("WCSessionReachabilityChanged")) {
        self?.isWatchReachable = WatchConnectivityService.shared.isReachable
      }
    }
  }

  func sendSOS() {
    isMonitoringActive = true
    statusText = "SOS Sent"
    WatchConnectivityService.shared.sendSOSAlert(
      facilityId: "preview",
      residentId: "preview"
    )
  }

  func simulateVitalUpdate() {
    heartRate = "\(Int.random(in: 60...100))"
    bloodOxygen = "\(Int.random(in: 92...100))%"
    lastSync = Date()
    statusText = "Monitoring"
    isMonitoringActive = true
    WatchConnectivityService.shared.sendVitalUpdate(
      facilityId: "preview",
      residentId: "preview",
      metric: "heart_rate",
      value: Double(heartRate) ?? 0
    )
  }

  func simulateAlert() {
    let types = ["Fall detected", "High heart rate", "Low SpO2", "Movement detected"]
    let alert = PreviewAlert(
      summary: types.randomElement()!,
      priority: Int.random(in: 1...3)
    )
    alerts.insert(alert, at: 0)
    if alerts.count > 10 { alerts = Array(alerts.prefix(10)) }
    lastSync = Date()
    if let data = try? JSONEncoder().encode(alert),
       let json = String(data: data, encoding: .utf8) {
      WatchConnectivityService.shared.sendAlertUpdate(alertJSON: json)
    }
  }
}
