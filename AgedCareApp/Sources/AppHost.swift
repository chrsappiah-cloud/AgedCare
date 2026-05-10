import Foundation

enum AppHost {
  static var baseURL: URL {
    #if targetEnvironment(simulator)
    URL(string: "http://localhost:8081")!
    #elseif DEBUG
    URL(string: "http://192.168.1.109:8081")!
    #else
    URL(string: "https://agedcare-api.chrsappiah.cloud")!
    #endif
  }

  static var supabaseAnonKey: String {
    #if DEBUG
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder"
    #else
    ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
      ?? Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String
      ?? ""
    #endif
  }
}
