import Foundation

enum AppHost {
  #if targetEnvironment(simulator)
  static let baseURL = URL(string: "http://localhost:8081")!
  #else
  static let baseURL = URL(string: "http://192.168.1.109:8081")!
  #endif
}
