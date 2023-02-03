# ComposableNavigation

This prototype is meant to show how features and dependencies can be designed using [ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture).

## SwiftUI Navigation
`Home` contains an optional `Destination` inside it's state and action properties, which is used to drive things like sheets, navigationlinks, etc.
Stores scope from global to local states, so that features can be built and understood in isolation.


```swift
  struct State: Equatable {
    var destination: Destination?
    
    enum Destination: Equatable {
      case account(Account.State)
      case players(Players.State)
      case sports(Sports.State)
      case activities(Activities.State)
      case settings(Settings.State)
      case sessionDetails(SessionDetails.State)
      case newSession(NewSession.State)
      case sessions(Sessions.State)
    }
  }
  
  enum Action: BindableAction, Equatable {
    case destination(Destination)
    
    enum Destination: Equatable {
      case account(Account.Action)
      case players(Players.Action)
      case sports(Sports.Action)
      case activities(Activities.Action)
      case settings(Settings.Action)
      case sessionDetails(SessionDetails.Action)
      case newSession(NewSession.Action)
      case sessions(Sessions.Action)
    }
  }
```

## Dependency Injection
[ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture) provides a way for injecting different previews during compilation, previews, and tests.
Dependencies are defined using `Structs` containing static implementations of async functions and streams, that can be globally injected from any Reducer.

Here's an example using the AuthClient:

```Swift
extension AuthClient {
  static var liveValue = Self.liveImplementation // used when the app is actually runnign 
  static var previewValue = Self.previewImplementation // used for previews 
  static var testValue = Self.testImplementation // used when writing tests (contains unimplemented functions)
}

```

