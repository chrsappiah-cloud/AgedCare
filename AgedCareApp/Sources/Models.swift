import Foundation

struct StaffUserModel {
  let id: UUID
  let facilityId: UUID
  let role: String
  let displayName: String?
  let email: String?
}

struct ResidentModel: Identifiable {
  let id: UUID
  let facilityId: UUID
  let name: String
  let riskLevel: String?
  let dateOfBirth: Date?
}

struct TimelineItem: Identifiable {
  let id: UUID
  let kind: TimelineKind
  let timestamp: Date
  let summary: String

  enum TimelineKind {
    case fall
    case vital
  }
}

enum SessionState {
  case onboarding
  case loading
  case resident(facilityId: UUID, residentId: UUID)
  case staff(StaffUserModel)
}

struct LoginResponse: Decodable {
  let accessToken: String
  let user: LoginUser

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case user
  }
}

struct LoginUser: Decodable {
  let id: String
  let email: String
  let role: String
}
