import SwiftUI
import AgedCareShared

struct InsightsView: View {
  let staff: StaffUserModel
  @EnvironmentObject var container: DependencyContainer
  @State private var stats: FacilityStatsDTO?
  @State private var loadError: String?

  var body: some View {
    NavigationStack {
      List {
        if let stats {
          Section("Last 7 days") {
            LabeledContent("Falls", value: "\(stats.falls_last_7d)")
            LabeledContent("Open alerts", value: "\(stats.open_alerts)")
            LabeledContent("Avg. acknowledge time", value: "\(stats.avg_acknowledge_minutes) min")
          }
        }
        if let error = loadError {
          Section {
            Text(error).foregroundColor(.red)
          }
        }
      }
      .navigationTitle("Insights")
      .refreshable { await loadStats() }
      .task { await loadStats() }
    }
  }

  private func loadStats() async {
    do {
      stats = try await container.facilityRepository.getStats(facilityId: staff.facilityId)
    } catch {
      loadError = error.localizedDescription
    }
  }
}
