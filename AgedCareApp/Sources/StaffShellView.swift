import SwiftUI

struct StaffShellView: View {
  let staff: StaffUserModel
  let session: SessionViewModel
  @EnvironmentObject var container: DependencyContainer

  var body: some View {
    TabView {
      AlertsHomeView(staff: staff)
        .tabItem {
          Label("Alerts", systemImage: "bell.badge.fill")
        }

      ResidentsHomeView(staff: staff)
        .tabItem {
          Label("Residents", systemImage: "person.3.fill")
        }

      InsightsView(staff: staff)
        .tabItem {
          Label("Insights", systemImage: "chart.bar.doc.horizontal.fill")
        }

      SettingsView(staff: staff, session: session)
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
    }
  }
}
