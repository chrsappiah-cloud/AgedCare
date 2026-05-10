import SwiftUI

struct WatchContentView: View {
  @EnvironmentObject var vm: WatchViewModel
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      statusView.tag(0)
      alertsView.tag(1)
      sosView.tag(2)
    }
    .tabViewStyle(.page)
    .onAppear { vm.requestContext() }
  }

  private var statusView: some View {
    ScrollView {
      VStack(spacing: 12) {
        Image(systemName: vm.isMonitoringActive ? "heart.circle.fill" : "heart.slash")
          .font(.title)
          .foregroundColor(vm.isMonitoringActive ? .green : .gray)

        Text(vm.monitoringStatus)
          .font(.headline)

        Divider()

        VStack(alignment: .leading, spacing: 8) {
          Label {
            Text("\(vm.heartRate) bpm")
              .font(.title3.bold())
          } icon: {
            Image(systemName: "heart.fill")
              .foregroundColor(.red)
          }

          Label {
            Text("\(vm.bloodOxygen) SpO2")
              .font(.title3.bold())
          } icon: {
            Image(systemName: "drop.fill")
              .foregroundColor(.blue)
          }
        }
        .padding(.vertical, 4)

        if let sync = vm.lastSync {
          Text("Updated\n\(sync.formatted(date: .omitted, time: .shortened))")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding()
    }
    .navigationTitle("AgedCare")
  }

  private var alertsView: some View {
    List {
      if vm.alerts.isEmpty {
        Text("No active alerts")
          .foregroundColor(.secondary)
      }
      ForEach(vm.alerts) { alert in
        HStack {
          Circle()
            .fill(alert.priority > 2 ? Color.red : Color.orange)
            .frame(width: 8, height: 8)
          VStack(alignment: .leading) {
            Text(alert.summary)
              .font(.caption.bold())
            Text(alert.timestamp)
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
        .padding(.vertical, 2)
      }
    }
    .navigationTitle("Alerts")
  }

  private var sosView: some View {
    VStack(spacing: 16) {
      Spacer()

      Button(action: vm.sendSOS) {
        ZStack {
          Circle()
            .fill(Color.red)
            .frame(width: 100, height: 100)
            .shadow(radius: 8)
          Text("SOS")
            .font(.title.bold())
            .foregroundColor(.white)
        }
      }
      .buttonStyle(.plain)
      .buttonBorderShape(.circle)
      .accessibilityLabel("Send SOS alert")
      .accessibilityHint("Triggers an emergency alert to all staff")

      Text("Emergency alert")
        .font(.caption)
        .foregroundColor(.secondary)

      Spacer()
    }
    .navigationTitle("Emergency")
  }
}
