import Foundation
import ComposableArchitecture

struct AuthClient: DependencyKey {
  var getUserProfile: @Sendable () async throws -> UserProfile?
  
  struct Failure: Equatable, Error {}
}

extension DependencyValues {
  var auth: AuthClient {
    get { self[AuthClient.self] }
    set { self[AuthClient.self] = newValue }
  }
}

// MARK: - Implementations

extension AuthClient {
  static var liveValue = Self.mock
}
