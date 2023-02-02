import ComposableArchitecture
import SwiftUI

struct Activities: ReducerProtocol {
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

struct ActivitiesView: View {
  let store: StoreOf<Activities>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Text("Placeholder Content".capitalized)
          .font(.title3)
          .bold()
          .foregroundStyle(.secondary)
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Activities")
      .searchable(text: viewStore.binding(\.$search))
    }
  }
}

// MARK: - SwiftUI Previews

struct ActivitiesView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ActivitiesView(
        store: Store(
          initialState: Activities.State(),
          reducer: Activities()
        )
      )
    }
  }
}
