import Foundation
import ComposableArchitecture

extension AuthClient {
  static var mock: Self {
    return Self(
      getUserProfile: {
        .init(
          id: .init(),
          firstName: "Kody",
          lastName: "Deda",
          joinDate: Date(),
          avatarURL: URL(string: "https://oldschool.runescape.wiki/images/Sir_Lancelot_chathead_%28historical%29.png?84879")!
        )
      }
    )
  }
}
