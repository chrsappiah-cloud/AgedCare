import Foundation

public protocol FacilityRepositoryProtocol: AnyObject {
  func getStats(facilityId: UUID) async throws -> FacilityStatsDTO
}

public final class FacilityRepository: FacilityRepositoryProtocol {
  private let supabase: SupabaseClient

  public init(supabase: SupabaseClient) {
    self.supabase = supabase
  }

  public func getStats(facilityId: UUID) async throws -> FacilityStatsDTO {
    let req = GetFacilityStatsRequest(p_facility_id: facilityId.uuidString)
    return try await supabase.rpc("get_facility_stats", payload: req)
  }
}
