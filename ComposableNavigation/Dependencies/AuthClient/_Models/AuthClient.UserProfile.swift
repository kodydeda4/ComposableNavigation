import Foundation
import Tagged

extension AuthClient {
  struct UserProfile {
    let id: ID
    var firstName: String
    var lastName: String
    var joinDate: Date
    var avatarURL: URL
    
    typealias ID = Tagged<Self, UUID>
  }
}

// MARK: - Protocol Conformance

extension AuthClient.UserProfile: Identifiable {}
extension AuthClient.UserProfile: Codable {}
extension AuthClient.UserProfile: Equatable {}
extension AuthClient.UserProfile: Hashable {}
