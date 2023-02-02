import Foundation
import Tagged

extension LocalDatabaseClient {
  struct Measurement {
    let id: ID
    let sessionID: Session.ID
    let measurement: Foundation.Measurement<UnitSpeed>
    
    typealias ID = Tagged<Self, UUID>
  }
}

// MARK: - Protocol Conformance

extension LocalDatabaseClient.Measurement: Identifiable {}
extension LocalDatabaseClient.Measurement: Codable {}
extension LocalDatabaseClient.Measurement: Equatable {}
extension LocalDatabaseClient.Measurement: Hashable {}
extension LocalDatabaseClient.Measurement: Comparable {
  static func < (lhs: LocalDatabaseClient.Measurement, rhs: LocalDatabaseClient.Measurement) -> Bool {
    lhs.measurement.value > rhs.measurement.value
  }
}
