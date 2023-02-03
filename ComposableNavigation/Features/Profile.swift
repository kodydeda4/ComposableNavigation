import ComposableArchitecture
import SwiftUI

struct Profile: ReducerProtocol {
  struct State: Equatable {
    @BindingState var profile: AuthClient.UserProfile?
  }
  
  enum Action: BindableAction, Equatable {
    case task
    case taskResponse(TaskResult<AuthClient.UserProfile>)
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.auth) var auth
  
  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
        
      case .task:
        return .task {
          await .taskResponse(TaskResult {
            if let userProfile = try await self.auth.getUserProfile() {
              return userProfile
            } else {
              struct Failure: Error, Equatable {}
              throw Failure()
            }
          })
        }
        
      case let .taskResponse(.success(value)):
        state.profile = value
        return .none
        
      case .taskResponse(.failure):
        return .none
      
      case .binding:
        return .none
        
      }
    }
  }
}

// MARK: - SwiftUI

struct SmallProfileView: View {
  let store: StoreOf<Profile>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      AsyncImage(
        url: viewStore.profile?.avatarURL,
        content: { $0.resizable().scaledToFit() },
        placeholder: ProgressView.init
      )
      .frame(width: 40, height: 40)
      .background(Color(.systemGray4))
      .clipShape(Circle())
      .padding(.trailing, 4)
    }
  }
}

struct ProfileView: View {
  let store: StoreOf<Profile>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      HStack {
        AsyncImage(
          url: viewStore.profile?.avatarURL,
          content: { $0.resizable().scaledToFit() },
          placeholder: ProgressView.init
        )
        .frame(width: 60, height: 60)
        .background(Color(.systemGray4))
        .clipShape(Circle())
        .padding(.trailing, 4)
        
        VStack(alignment: .leading) {
          Text("\(viewStore.profile?.firstName ?? "") \(viewStore.profile?.lastName ?? "")")
            .font(.title2)
          
          Text("Member since \(viewStore.profile?.joinDate.formatted() ?? "")")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
      .task { viewStore.send(.task) }
    }
  }
}


// MARK: - SwiftUI Previews

struct ProfileView_Previews: PreviewProvider {
  static let store = Store(
    initialState: Profile.State(),
    reducer: Profile()
  )
  
  static var previews: some View {
    NavigationStack {
      List {
        ProfileView(store: store)
      }
      .navigationTitle("Preview")
      .toolbar {
        Button(action: {}) {
          SmallProfileView(store: store)
        }
      }
    }
  }
}
