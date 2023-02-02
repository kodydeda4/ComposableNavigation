import ComposableArchitecture
import SwiftUI

struct Account: ReducerProtocol {
  struct State: Equatable {
    var profile: Profile.State
  }
  
  enum Action: BindableAction, Equatable {
    case task
    case logoutButtonTapped
    case profile(Profile.Action)
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.auth) var auth
  
  var body: some ReducerProtocol<State, Action> {
    BindingReducer()
    Scope(state: \.profile, action: /Action.profile) {
      Profile()
    }
    Reduce { state, action in
      switch action {
        
      case .task:
        return .none
        
      case .logoutButtonTapped:
        return .none
        
      case .profile:
        return .none
        
      case .binding:
        return .none
        
      }
    }
  }
}

// MARK: - SwiftUI

struct AccountView: View {
  let store: StoreOf<Account>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        List {
          Section {
            NavigationLink(
              destination: { Text("N.A.") },
              label: {
                ProfileView(store: store.scope(
                  state: \.profile,
                  action: Account.Action.profile
                ))
              }
            )
          }
          
          Section {
            NavigationLink(
              destination: { Text("N.A.") },
              label: { PocketRadarPlusBanner() }
            )
          }
          .listRowBackground(Color.accentColor)
          .foregroundColor(.white)
          
          Section {
            Button("Restore Purchases") {
              //...
            }
            .foregroundColor(.blue)
            
            Button("Rate This App") {
              //...
            }
            .foregroundColor(.blue)
            
            Button("Shop Accessories") {
              //...
            }
            .foregroundColor(.blue)
          }
          
          Section("Customer Support") {
            NavigationLink(destination: { Text("N.A.") }) {
              Label("Contact Us", systemImage: "phone")
            }
            NavigationLink(destination: { Text("N.A.") }) {
              Label("FAQs", systemImage: "questionmark")
            }
            NavigationLink(destination: { Text("N.A.") }) {
              Label("Legal", systemImage: "character.book.closed")
            }
          }
          
          Section {
            Button(
              "Log Out",
              role: .destructive,
              action: { viewStore.send(.logoutButtonTapped) }
            )
          }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
      }
    }
  }
}

private struct PocketRadarPlusBanner: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Try ")
        .font(.title3)
      +
      Text("PocketRadar +")
        .font(.title3)
        .fontWeight(.bold)
      
      Text("Unlock premium features like PitchCharting, High-Framerate Videos, ComputerVision, and more.")
        .font(.caption)
      
      Text("Free for 30 Days")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(
          cornerRadius: 30,
          style: .continuous
        ))
    }
    .foregroundColor(.white)
  }
}

// MARK: - SwiftUI Previews

struct AccountView_Previews: PreviewProvider {
  static var previews: some View {
    AccountView(
      store: Store(
        initialState: Account.State(
          profile: .init()
        ),
        reducer: Account()
      )
    )
  }
}
