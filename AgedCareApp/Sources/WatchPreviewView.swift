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
            .stroke(Color(.systemGray3), lineWidth: 2)
        )
        .shadow(radius: 10)
      watchControls
    }
    .padding()
    .navigationTitle("Watch Preview")
  }

  private let watchSize = CGSize(width: 180, height: 215)

  private var watchHeader: some View {
    HStack {
      Circle().fill(.green).frame(width: 6, height: 6)
      Text("Connected")
        .font(.caption2)
        .foregroundColor(.secondary)
      Spacer()
      Text(formattedTime)
        .font(.caption2)
        .foregroundColor(.secondary)
        .monospacedDigit()
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .frame(width: watchSize.width)
    .background(Color.black.opacity(0.05))
    .cornerRadius(8)
  }

  private var watchScreen: some View {
    TabView(selection: $selectedTab) {
      watchStatusView.tag(0)
      watchAlertsView.tag(1)
      watchSOSView.tag(2)
    }
    .tabViewStyle(.page)
    .background(Color.black)
  }

  private var watchStatusView: some View {
    ScrollView {
      VStack(spacing: 8) {
        Image(systemName: vm.isMonitoringActive ? "heart.circle.fill" : "heart.slash")
          .font(.title2)
          .foregroundColor(vm.isMonitoringActive ? .green : .gray)

        Text(vm.statusText)
          .font(.caption.bold())
          .foregroundColor(.white)

        Divider().background(.gray)

        Label {
          Text("\(vm.heartRate) bpm")
            .font(.caption.bold())
            .foregroundColor(.white)
        } icon: {
          Image(systemName: "heart.fill").foregroundColor(.red).font(.caption)
        }

        Label {
          Text("\(vm.bloodOxygen) SpO2")
            .font(.caption.bold())
            .foregroundColor(.white)
        } icon: {
          Image(systemName: "drop.fill").foregroundColor(.blue).font(.caption)
        }

        Text("Updated \(vm.lastSync.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 8))
          .foregroundColor(.gray)
      }
      .padding(8)
    }
    .background(Color.black)
  }

  private var watchAlertsView: some View {
    List {
      if vm.alerts.isEmpty {
        Text("No active alerts")
          .font(.caption2)
          .foregroundColor(.gray)
      }
      ForEach(vm.alerts) { alert in
        HStack(spacing: 4) {
          Circle()
            .fill(alert.priority > 2 ? Color.red : Color.orange)
            .frame(width: 6, height: 6)
          Text(alert.summary)
            .font(.system(size: 9))
            .foregroundColor(.white)
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.black)
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
            .fill(Color.red)
            .frame(width: 70, height: 70)
            .shadow(radius: 4)
          Text("SOS")
            .font(.caption.bold())
            .foregroundColor(.white)
        }
      }
      .buttonStyle(.plain)

      if showSOSConfirmation {
        Text("Alert sent!")
          .font(.system(size: 9))
          .foregroundColor(.green)
          .transition(.opacity)
      } else {
        Text("Emergency alert")
          .font(.system(size: 8))
          .foregroundColor(.gray)
      }
      Spacer()
    }
    .background(Color.black)
  }

  private var watchControls: some View {
    HStack(spacing: 16) {
      Button(action: { selectedTab = 0 }) {
        Label("Status", systemImage: "heart.fill")
          .font(.caption2)
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.bordered)
      .tint(selectedTab == 0 ? .accentColor : .gray)

      Button(action: { selectedTab = 1 }) {
        Label("Alerts", systemImage: "bell.fill")
          .font(.caption2)
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.bordered)
      .tint(selectedTab == 1 ? .accentColor : .gray)

      Button(action: { selectedTab = 2 }) {
        Label("SOS", systemImage: "exclamationmark.triangle.fill")
          .font(.caption2)
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.bordered)
      .tint(selectedTab == 2 ? .accentColor : .gray)

      Spacer()

      Button(action: vm.simulateVitalUpdate) {
        Image(systemName: "arrow.triangle.2.circlepath")
          .font(.caption2)
      }
      .buttonStyle(.bordered)
      .tint(.blue)
      .accessibilityLabel("Simulate vital update")

      Button(action: vm.simulateAlert) {
        Image(systemName: "bell.badge")
          .font(.caption2)
      }
      .buttonStyle(.bordered)
      .tint(.orange)
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
  @Published var lastSync = Date()
  @Published var alerts: [PreviewAlert] = []

  struct PreviewAlert: Identifiable {
    let id = UUID()
    let summary: String
    let priority: Int
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
  }
}
