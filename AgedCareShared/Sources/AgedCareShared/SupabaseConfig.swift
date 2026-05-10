import Foundation

public struct SupabaseConfig {
  public let baseURL: URL
  public let apiKey: String

  public init(baseURL: URL, apiKey: String) {
    self.baseURL = baseURL
    self.apiKey = apiKey
  }
}
