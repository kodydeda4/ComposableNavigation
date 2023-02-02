import ComposableArchitecture
import SwiftUI

struct Settings: ReducerProtocol {
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

struct SettingsView: View {
  let store: StoreOf<Settings>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Text("Placeholder Content".capitalized)
          .font(.title3)
          .bold()
          .foregroundStyle(.secondary)
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Settings")
      .searchable(text: viewStore.binding(\.$search))
    }
  }
}

// MARK: - SwiftUI Previews

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SettingsView(
        store: Store(
          initialState: Settings.State(),
          reducer: Settings()
        )
      )
    }
  }
}
