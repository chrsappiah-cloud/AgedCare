import SwiftUI
import AgedCareShared

struct ResidentOverviewView: View {
  let resident: ResidentModel
  @EnvironmentObject var container: DependencyContainer
  @State private var fallSummary7d: Int = 0
  @State private var fallSummary30d: Int = 0
  @State private var loadError: String?

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        header
        if let error = loadError {
          Text(error).foregroundColor(.red)
        }
        summaryCards
        NavigationLink("View detailed timeline") {
          ResidentTimelineView(resident: resident)
        }
        .buttonStyle(.borderedProminent)
        Spacer()
      }
      .padding()
    }
    .navigationTitle(resident.name)
    .task { await loadFallSummary() }
  }

  private var header: some View {
    HStack(spacing: 16) {
      ProfileImageView(name: resident.name, imageURL: nil, size: .medium)
      VStack(alignment: .leading, spacing: 4) {
        Text(resident.name)
          .font(.title2.bold())
        if let risk = resident.riskLevel {
          Text("Risk: \(risk.capitalized)")
            .font(.subheadline)
            .foregroundColor(risk.lowercased() == "high" ? .red : .secondary)
        }
      }
      Spacer()
    }
  }

  private var summaryCards: some View {
    HStack(spacing: 12) {
      statCard(title: "Falls (7d)", value: "\(fallSummary7d)")
      statCard(title: "Falls (30d)", value: "\(fallSummary30d)")
    }
  }

  private func statCard(title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
      Text(value)
        .font(.headline)
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
  }

  private func loadFallSummary() async {
    do {
      async let seven = container.residentsRepository.getFallCount(residentId: resident.id, days: 7)
      async let thirty = container.residentsRepository.getFallCount(residentId: resident.id, days: 30)
      (fallSummary7d, fallSummary30d) = try await (seven, thirty)
    } catch {
      loadError = error.localizedDescription
    }
  }
}
