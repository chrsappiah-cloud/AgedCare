import Foundation
import AgedCareShared

final class DependencyContainer: ObservableObject {
  let supabase: SupabaseClient
  let alertsRepository: AlertsRepository
  let residentsRepository: ResidentsRepository
  let facilityRepository: FacilityRepository
  init() {
    let config = SupabaseConfig(
      baseURL: AppHost.baseURL,
      apiKey: AppHost.supabaseAnonKey
    )
    supabase = SupabaseClient(
      config: config,
      accessTokenProvider: { SupabaseAuthStore.shared.accessToken }
    )
    alertsRepository = AlertsRepository(supabase: supabase)
    residentsRepository = ResidentsRepository(supabase: supabase)
    facilityRepository = FacilityRepository(supabase: supabase)
  }

  func makeFallService(facilityId: UUID, residentId: UUID) -> FallService {
    let engine = FallDetectionEngine()
    return FallService(
      engine: engine,
      alertsRepository: alertsRepository,
      facilityId: facilityId,
      residentId: residentId
    )
  }
}

final class SupabaseAuthStore {
  static let shared = SupabaseAuthStore()
  var accessToken: String?
}
