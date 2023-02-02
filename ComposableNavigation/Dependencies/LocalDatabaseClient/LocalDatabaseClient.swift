import Foundation
import ComposableArchitecture

struct LocalDatabaseClient: DependencyKey {
  ///`Session`
  var getSessions: @Sendable () async throws -> [Session]
  var upsertSession: @Sendable (Session) async throws -> Void
  
  ///`Measurement`
  var getMeasurement: @Sendable (Measurement.ID) async throws -> Measurement?
  var upsertMeasurement: @Sendable (Measurement) async throws -> Void
  
  struct Failure: Equatable, Error {}
}

extension DependencyValues {
  var database: LocalDatabaseClient {
    get { self[LocalDatabaseClient.self] }
    set { self[LocalDatabaseClient.self] = newValue }
  }
}

// MARK: - Implementations

extension LocalDatabaseClient {
  static var liveValue = Self.mock
}
