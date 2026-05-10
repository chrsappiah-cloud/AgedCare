import SwiftUI
import AgedCareShared

struct ResidentsHomeView: View {
  let staff: StaffUserModel
  @EnvironmentObject var container: DependencyContainer
  @State private var searchText = ""
  @State private var residents: [ResidentModel] = []
  @State private var isLoading = false
  @State private var loadError: String?

  var body: some View {
    NavigationStack {
      List(filteredResidents) { res in
        NavigationLink {
          ResidentOverviewView(resident: res)
        } label: {
          HStack {
            Text(res.name)
            Spacer()
            if res.riskLevel == "high" {
              Text("HIGH RISK")
                .font(.caption2)
                .padding(4)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(4)
            }
          }
        }
      }
      .navigationTitle("Residents")
      .searchable(text: $searchText)
      .refreshable { await loadResidents() }
      .task { await loadResidents() }
      .overlay {
        if isLoading { ProgressView("Loading\u{2026}") }
        else if let error = loadError { Text(error).foregroundColor(.red).padding() }
        else if residents.isEmpty { Text("No residents found").foregroundColor(.secondary) }
      }
    }
  }

  private var filteredResidents: [ResidentModel] {
    guard !searchText.isEmpty else { return residents }
    return residents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
  }

  private func loadResidents() async {
    isLoading = true
    loadError = nil
    defer { isLoading = false }
    do {
      let dtos = try await container.residentsRepository.getResidents(facilityId: staff.facilityId)
      residents = dtos.map { dto in
        ResidentModel(
          id: dto.id,
          facilityId: dto.facility_id,
          name: dto.name,
          riskLevel: dto.risk_level,
          dateOfBirth: dto.date_of_birth.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
      }
    } catch {
      loadError = error.localizedDescription
    }
  }
}
