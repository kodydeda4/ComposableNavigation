import SwiftUI
import ComposableArchitecture

@main
struct Main: App {
  var body: some Scene {
    WindowGroup {
      RootView(store: .init(
        initialState: Root.State(),
        reducer: Root()
      ))
    }
  }
}
