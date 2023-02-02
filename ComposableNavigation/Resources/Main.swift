import SwiftUI
import ComposableArchitecture

@main
struct Main: App {
  var body: some Scene {
    WindowGroup {
      HomeView(store: .init(
        initialState: Home.State(),
        reducer: Home()
      ))
    }
  }
}
