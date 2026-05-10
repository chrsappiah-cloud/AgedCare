import SwiftUI
import AgedCareShared

struct ResidentSetupView: View {
  @EnvironmentObject var container: DependencyContainer
  @EnvironmentObject var session: SessionViewModel
  @State private var residents: [ResidentModel] = []
  @State private var isLoading = true
  @State private var errorMessage: String?
  @State private var facilityId: UUID?

  var body: some View {
    NavigationStack {
      Group {
        if isLoading {
          ProgressView("Loading residents\u{2026}")
        } else if let error = errorMessage {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 48))
              .foregroundColor(.orange)
            Text(error)
              .foregroundColor(.secondary)
            Button("Retry") { load() }
              .buttonStyle(.bordered)
          }
        } else if residents.isEmpty {
          ContentUnavailableView(
            "No Residents",
            systemImage: "person.slash",
            description: Text("No residents found for this facility.")
          )
        } else {
          List(residents) { resident in
            Button(action: { select(resident) }) {
              ResidentRow(resident: resident)
            }
          }
          .navigationTitle("Select Resident")
        }
      }
      .onAppear(perform: load)
    }
  }

  private func load() {
    isLoading = true
    errorMessage = nil
    Task {
      do {
        facilityId = try await findFacilityId()
        guard let fid = facilityId else {
          errorMessage = "No facility available"
          isLoading = false
          return
        }
        let dtos = try await container.residentsRepository.getResidents(facilityId: fid)
        residents = dtos.map { dto in
          ResidentModel(
            id: dto.id,
            facilityId: dto.facility_id,
            name: dto.name,
            riskLevel: dto.risk_level,
            dateOfBirth: dto.date_of_birth.flatMap { ISO8601DateFormatter().date(from: $0) }
          )
        }
        isLoading = false
      } catch {
        errorMessage = error.localizedDescription
        isLoading = false
      }
    }
  }

  private func select(_ resident: ResidentModel) {
    session.setResident(facilityId: resident.facilityId, residentId: resident.id)
  }

  private func findFacilityId() async throws -> UUID? {
    var req = URLRequest(url: AppHost.baseURL.appendingPathComponent("/facility"))
    req.httpMethod = "GET"
    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let idString = json?["id"] as? String else { return nil }
    return UUID(uuidString: idString)
  }
}

struct ResidentRow: View {
  let resident: ResidentModel

  @State private var showCamera = false
  @State private var showPhotoLibrary = false
  @State private var profileImage: UIImage?

  var body: some View {
    HStack(spacing: 12) {
      ZStack {
        if let img = profileImage {
          Image(uiImage: img)
            .resizable()
            .scaledToFill()
            .frame(width: 48, height: 48)
            .clipShape(Circle())
        } else {
          ProfileImageView(name: resident.name, imageURL: nil, size: .custom(48))
        }
      }
      .onTapGesture {
        showCamera = true
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(resident.name)
          .font(.headline)
          .foregroundColor(.primary)
        HStack {
          if let risk = resident.riskLevel {
            Badge(risk, color: riskColor(risk))
          }
          if let dob = resident.dateOfBirth {
            Text(dob.formatted(date: .abbreviated, time: .omitted))
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
    .confirmationDialog("Add photo", isPresented: $showCamera) {
      Button("Camera") { showCamera = true }
      Button("Photo Library") { showPhotoLibrary = true }
      Button("Cancel", role: .cancel) {}
    }
    .sheet(isPresented: $showPhotoLibrary) {
      ImagePicker(sourceType: .photoLibrary, onPick: { image in
        profileImage = image
      }, onCancel: {})
    }
    .sheet(isPresented: $showCamera) {
      ImagePicker(sourceType: .camera, onPick: { image in
        profileImage = image
      }, onCancel: {})
    }
  }

  private func riskColor(_ risk: String) -> Color {
    switch risk.lowercased() {
    case "high": return .red
    case "medium": return .orange
    case "low": return .green
    default: return .gray
    }
  }
}

struct Badge: View {
  let text: String
  let color: Color

  init(_ text: String, color: Color) {
    self.text = text
    self.color = color
  }

  var body: some View {
    Text(text.capitalized)
      .font(.caption2.bold())
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .background(color.opacity(0.2))
      .foregroundColor(color)
      .cornerRadius(6)
  }
}
