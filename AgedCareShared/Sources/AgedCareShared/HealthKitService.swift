import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

public enum HealthKitError: LocalizedError {
  case notAvailable
  case notAuthorized
  case queryFailed(String)

  public var errorDescription: String? {
    switch self {
    case .notAvailable: return "HealthKit not available on this device"
    case .notAuthorized: return "HealthKit access not authorized"
    case .queryFailed(let msg): return "Health query failed: \(msg)"
    }
  }
}

#if canImport(HealthKit)
public struct VitalReading: Sendable {
  public let type: HKQuantityTypeIdentifier
  public let value: Double
  public let unit: HKUnit
  public let timestamp: Date

  public init(type: HKQuantityTypeIdentifier, value: Double, unit: HKUnit, timestamp: Date) {
    self.type = type
    self.value = value
    self.unit = unit
    self.timestamp = timestamp
  }
}
#else
public struct VitalReading: Sendable {
  public let type: String
  public let value: Double
  public let unit: String
  public let timestamp: Date

  public init(type: String, value: Double, unit: String, timestamp: Date) {
    self.type = type
    self.value = value
    self.unit = unit
    self.timestamp = timestamp
  }
}
#endif

public enum VitalAlert: Sendable {
  case highHeartRate(reading: VitalReading)
  case lowHeartRate(reading: VitalReading)
  case lowBloodOxygen(reading: VitalReading)
  case fallImpact(acceleration: Double)
}

#if canImport(HealthKit)

public final class HealthKitService: @unchecked Sendable {
  public static let shared = HealthKitService()
  private let store = HKHealthStore()
  private var isAuthorized = false

  private init() {}

  public var isAvailable: Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  public func requestAuthorization() async throws {
    guard isAvailable else { throw HealthKitError.notAvailable }

    let typesToRead: Set<HKObjectType> = [
      HKObjectType.quantityType(forIdentifier: .heartRate)!,
      HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
      HKObjectType.quantityType(forIdentifier: .stepCount)!,
      HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
      HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
    ]

    let typesToWrite: Set<HKSampleType> = [
      HKObjectType.quantityType(forIdentifier: .heartRate)!,
    ]

    try await store.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    isAuthorized = true
  }

  public func latestHeartRate() async throws -> VitalReading {
    try await latestQuantity(type: .heartRate, unit: .count().unitDivided(by: .minute()))
  }

  public func latestBloodOxygen() async throws -> VitalReading {
    try await latestQuantity(type: .oxygenSaturation, unit: .percent())
  }

  public func latestStepCount() async throws -> VitalReading {
    try await latestQuantity(type: .stepCount, unit: .count())
  }

  private func latestQuantity(type: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> VitalReading {
    guard isAuthorized else { throw HealthKitError.notAuthorized }
    let quantityType = HKQuantityType.quantityType(forIdentifier: type)!

    let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

    return try await withCheckedThrowingContinuation { cont in
      let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
        if let error = error {
          cont.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
          return
        }
        guard let sample = samples?.first as? HKQuantitySample else {
          cont.resume(throwing: HealthKitError.queryFailed("No data found"))
          return
        }
        let reading = VitalReading(
          type: type, value: sample.quantity.doubleValue(for: unit),
          unit: unit, timestamp: sample.startDate
        )
        cont.resume(returning: reading)
      }
      self.store.execute(query)
    }
  }

  public func startHeartRateMonitoring(interval: TimeInterval = 60) -> AsyncThrowingStream<VitalReading, Error> {
    AsyncThrowingStream { [weak self] continuation in
      guard let self = self, self.isAuthorized else {
        continuation.finish(throwing: HealthKitError.notAuthorized)
        return
      }

      let task = Task {
        while !Task.isCancelled {
          do {
            let reading = try await self.latestHeartRate()
            continuation.yield(reading)
          } catch {
            continuation.finish(throwing: error)
            return
          }
          try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  public func detectAbnormalVitals(reading: VitalReading) -> VitalAlert? {
    switch reading.type {
    case .heartRate:
      if reading.value > 120 { return .highHeartRate(reading: reading) }
      if reading.value < 40 { return .lowHeartRate(reading: reading) }
    case .oxygenSaturation:
      if reading.value < 0.90 { return .lowBloodOxygen(reading: reading) }
    default: break
    }
    return nil
  }
}

#else

public final class HealthKitService: @unchecked Sendable {
  public static let shared = HealthKitService()
  private init() {}

  public var isAvailable: Bool { false }

  public func requestAuthorization() async throws {
    throw HealthKitError.notAvailable
  }

  public func latestHeartRate() async throws -> VitalReading {
    throw HealthKitError.notAvailable
  }

  public func latestBloodOxygen() async throws -> VitalReading {
    throw HealthKitError.notAvailable
  }

  public func latestStepCount() async throws -> VitalReading {
    throw HealthKitError.notAvailable
  }

  public func startHeartRateMonitoring(interval: TimeInterval = 60) -> AsyncThrowingStream<VitalReading, Error> {
    AsyncThrowingStream { $0.finish(throwing: HealthKitError.notAvailable) }
  }

  public func detectAbnormalVitals(reading: VitalReading) -> VitalAlert? {
    nil
  }
}

#endif
