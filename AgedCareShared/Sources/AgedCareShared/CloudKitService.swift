#if canImport(CloudKit)
import CloudKit

public final class CloudKitService {
  public static let shared = CloudKitService()
  private let container: CKContainer

  private init(container: CKContainer = .default()) {
    self.container = container
  }

  public var privateDB: CKDatabase { container.privateCloudDatabase }
  public var publicDB: CKDatabase { container.publicCloudDatabase }

  @discardableResult
  public func save(_ record: CKRecord, in db: CKDatabase? = nil) async throws -> CKRecord {
    try await (db ?? privateDB).save(record)
  }

  public func query(
    recordType: String,
    predicate: NSPredicate = NSPredicate(value: true),
    in db: CKDatabase? = nil
  ) async throws -> [CKRecord] {
    let operation = CKQueryOperation(query: CKQuery(recordType: recordType, predicate: predicate))
    var results: [CKRecord] = []
    operation.recordMatchedBlock = { _, result in
      if case .success(let record) = result {
        results.append(record)
      }
    }
    return try await withCheckedThrowingContinuation { cont in
      operation.queryResultBlock = { result in
        switch result {
        case .success:
          cont.resume(returning: results)
        case .failure(let error):
          cont.resume(throwing: error)
        }
      }
      (db ?? self.privateDB).add(operation)
    }
  }
}
#endif
