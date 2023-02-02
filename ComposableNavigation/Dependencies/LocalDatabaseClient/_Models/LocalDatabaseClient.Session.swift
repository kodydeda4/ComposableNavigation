import Foundation
import Tagged

extension LocalDatabaseClient {
  struct Session {
    let id: ID
    var measurementIDs: [Measurement.ID]
    
    typealias ID = Tagged<Self, UUID>
  }
}

// MARK: - Protocol Conformance

extension LocalDatabaseClient.Session: Identifiable {}
extension LocalDatabaseClient.Session: Codable {}
extension LocalDatabaseClient.Session: Equatable {}
extension LocalDatabaseClient.Session: Hashable {}
