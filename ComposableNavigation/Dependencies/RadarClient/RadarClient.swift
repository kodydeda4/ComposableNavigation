import Foundation
import ComposableArchitecture

struct RadarClient: DependencyKey {
  var connect: @Sendable () async throws -> Radar
  var stream: @Sendable () async throws -> AsyncStream<Speed>
  
  struct Failure: Equatable, Error {}
}

extension DependencyValues {
  var radar: RadarClient {
    get { self[RadarClient.self] }
    set { self[RadarClient.self] = newValue }
  }
}

// MARK: - Implementations

extension RadarClient {
  static var liveValue = Self.mock
  //static var previewValue = Self.mock
  //static var testValue = Self.test
}

