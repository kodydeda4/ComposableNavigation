import ComposableArchitecture
import SwiftUI

struct Sports: ReducerProtocol {
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

struct SportsView: View {
  let store: StoreOf<Sports>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Text("Placeholder Content".capitalized)
          .font(.title3)
          .bold()
          .foregroundStyle(.secondary)
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Sports")
      .searchable(text: viewStore.binding(\.$search))
    }
  }
}

// MARK: - SwiftUI Previews

struct SportsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SportsView(
        store: Store(
          initialState: Sports.State(),
          reducer: Sports()
        )
      )
    }
  }
}
