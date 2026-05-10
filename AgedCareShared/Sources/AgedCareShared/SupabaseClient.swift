import Foundation

public final class SupabaseClient {
  private let config: SupabaseConfig
  private let session: URLSession
  private let accessTokenProvider: () -> String?

  public init(
    config: SupabaseConfig,
    session: URLSession = .shared,
    accessTokenProvider: @escaping () -> String?
  ) {
    self.config = config
    self.session = session
    self.accessTokenProvider = accessTokenProvider
  }

  public func rpc<T: Decodable>(_ name: String, payload: Encodable) async throws -> T {
    let data = try await performRPC(name, payload: payload)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw SupabaseError.decodingError(error)
    }
  }

  public func rpcVoid(_ name: String, payload: Encodable) async throws {
    try await performRPC(name, payload: payload)
  }

  private func performRPC(_ name: String, payload: Encodable) async throws -> Data {
    var url = config.baseURL
    url.appendPathComponent("/rest/v1/rpc/\(name)")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(config.apiKey, forHTTPHeaderField: "apikey")
    if let token = accessTokenProvider() {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    request.httpBody = try encoder.encode(AnyEncodable(payload))

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw SupabaseError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1, data)
    }
    return data
  }
}

public struct AnyEncodable: Encodable {
  private let encodeFunc: (Encoder) throws -> Void

  public init(_ encodable: Encodable) {
    self.encodeFunc = encodable.encode
  }

  public func encode(to encoder: Encoder) throws {
    try encodeFunc(encoder)
  }
}
