import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
  @Published var state: SessionState = .onboarding
  @Published var loginError: String?

  private let baseURL = URL(string: "http://localhost:8081")!

  func setResident(facilityId: UUID, residentId: UUID) {
    state = .resident(facilityId: facilityId, residentId: residentId)
  }

  func login(email: String, password: String) async {
    state = .loading
    loginError = nil

    do {
      // 1. Authenticate
      var req = URLRequest(url: baseURL.appendingPathComponent("/auth/v1/token"))
      req.httpMethod = "POST"
      req.setValue("application/json", forHTTPHeaderField: "Content-Type")
      let body: [String: String] = [
        "email": email, "password": password, "grant_type": "password",
      ]
      req.httpBody = try JSONEncoder().encode(body)

      let (data, resp) = try await URLSession.shared.data(for: req)
      guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
        throw LoginError.invalidCredentials
      }

      let loginResp = try JSONDecoder().decode(LoginResponse.self, from: data)
      SupabaseAuthStore.shared.accessToken = loginResp.accessToken

      // 2. Fetch staff info
      let userId = UUID(uuidString: loginResp.user.id)!
      var rpcReq = URLRequest(url: baseURL.appendingPathComponent("/rest/v1/rpc/get_staff_info"))
      rpcReq.httpMethod = "POST"
      rpcReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
      rpcReq.setValue("Bearer \(loginResp.accessToken)", forHTTPHeaderField: "Authorization")
      let rpcBody: [String: String] = ["p_user_id": loginResp.user.id]
      rpcReq.httpBody = try JSONEncoder().encode(rpcBody)

      let (staffData, staffResp) = try await URLSession.shared.data(for: rpcReq)
      guard let staffHttp = staffResp as? HTTPURLResponse, staffHttp.statusCode == 200 else {
        throw LoginError.staffNotFound
      }

      let staffInfo = try JSONDecoder().decode(StaffInfoResponse.self, from: staffData)
      let staff = StaffUserModel(
        id: userId,
        facilityId: UUID(uuidString: staffInfo.facilityId)!,
        role: staffInfo.role,
        displayName: staffInfo.displayName,
        email: loginResp.user.email
      )
      state = .staff(staff)

    } catch let error as LoginError {
      loginError = error.localizedDescription
      state = .onboarding
    } catch {
      loginError = "Connection failed. Check the server."
      state = .onboarding
    }
  }

  func logout() {
    SupabaseAuthStore.shared.accessToken = nil
    state = .onboarding
  }
}

enum LoginError: LocalizedError {
  case invalidCredentials
  case staffNotFound

  var errorDescription: String? {
    switch self {
    case .invalidCredentials: return "Invalid email or password"
    case .staffNotFound: return "Staff account not found"
    }
  }
}

struct StaffInfoResponse: Decodable {
  let id: String
  let facilityId: String
  let role: String
  let displayName: String?

  enum CodingKeys: String, CodingKey {
    case id
    case facilityId = "facility_id"
    case role
    case displayName = "display_name"
  }
}
