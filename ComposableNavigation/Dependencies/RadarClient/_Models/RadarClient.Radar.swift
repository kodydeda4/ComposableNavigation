import Foundation
import Tagged

extension RadarClient {
  struct Radar {
    let id: ID
    var isConnected = false
    
    typealias ID = Tagged<Self, UUID>
  }
}

// MARK: - Protocol Conformance

extension RadarClient.Radar: Identifiable {}
extension RadarClient.Radar: Codable {}
extension RadarClient.Radar: Equatable {}
extension RadarClient.Radar: Hashable {}
