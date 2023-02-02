import Foundation
import Tagged

extension RadarClient {
  struct Speed {
    let id: ID
    let measurement: Foundation.Measurement<UnitSpeed>
    
    typealias ID = Tagged<Self, UUID>
  }
}

// MARK: - Protocol Conformance

extension RadarClient.Speed: Identifiable {}
extension RadarClient.Speed: Codable {}
extension RadarClient.Speed: Equatable {}
extension RadarClient.Speed: Hashable {}
extension RadarClient.Speed: Comparable {
  static func < (lhs: RadarClient.Speed, rhs: RadarClient.Speed) -> Bool {
    lhs.measurement.value > rhs.measurement.value
  }
}
