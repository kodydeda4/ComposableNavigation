import SwiftUI
import ComposableArchitecture

@main
struct Main: App {
  var body: some Scene {
    WindowGroup {
      PocketRadarView(store: .init(
        initialState: PocketRadar.State(),
        reducer: PocketRadar()
      ))
    }
  }
}
