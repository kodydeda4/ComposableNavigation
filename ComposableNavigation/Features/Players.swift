import ComposableArchitecture
import SwiftUI

struct Players: ReducerProtocol {
  struct State: Equatable {
    @BindingState var search = String()
  }
  
  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      
      case .binding:
        return .none
        
      }
    }
  }
}

// MARK: - SwiftUI

struct PlayersView: View {
  let store: StoreOf<Players>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Text("Placeholder Content".capitalized)
          .font(.title3)
          .bold()
          .foregroundStyle(.secondary)
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Players")
      .searchable(text: viewStore.binding(\.$search))
    }
  }
}

// MARK: - SwiftUI Previews

struct PlayersView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      PlayersView(
        store: Store(
          initialState: Players.State(),
          reducer: Players()
        )
      )
    }
  }
}
