import Foundation

public enum SupabaseError: Error {
  case httpError(Int, Data)
  case decodingError(Error)
}
