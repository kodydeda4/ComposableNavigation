import ComposableArchitecture
import SwiftUI

struct Home: ReducerProtocol {
  struct State: Equatable {
    var profile = Profile.State()
    var recentSessions = IdentifiedArrayOf<SessionRow.State>()
    var destination: Destination?
    @BindingState var search = String()
    @BindingState var isFiltering = false
    
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
    case task
    case taskResponse(TaskResult<[LocalDatabaseClient.Session]>)
    case toggleIsFiltering
    case newSessionButtonTapped
    case binding(BindingAction<State>)
    case profileButtonTapped
    case setDestination(State.Destination?)
    case profile(Profile.Action)
    case recentSessions(id: SessionRow.State.ID, action: SessionRow.Action)
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
  
  @Dependency(\.database) var database
  
  var body: some ReducerProtocol<State, Action> {
    BindingReducer()
    Scope(state: \.profile, action: /Action.profile) {
      Profile()
    }
    Reduce { state, action in
      switch action {
        
      case .task:
        return .task {
          await .taskResponse(TaskResult {
            try await self.database.getSessions()
          })
        }
        
      case let .taskResponse(.success(values)):
        state.recentSessions = .init(uniqueElements: values.map {
          SessionRow.State(session: $0)
        })
        return .none
        
      case .taskResponse(.failure):
        return .none
        
      case .toggleIsFiltering:
        state.isFiltering.toggle()
        return .none
        
      case .profileButtonTapped:
        state.destination = .account(Account.State(profile: state.profile))
        return .none
        
      case .newSessionButtonTapped:
        state.destination = .newSession(NewSession.State())
        return .none
        
      case .recentSessions:
        return .none
        
      case .profile:
        return .none
        
      case let .setDestination(value):
        state.destination = value
        return .none
        
      case .destination(.newSession(.dismiss)):
        state.destination = nil
        return .send(.task)
        
      case .destination:
        return .none
        
      case .binding:
        return .none
      }
    }
    .forEach(\.recentSessions, action: /Action.recentSessions) {
      SessionRow()
    }
    .ifLet(\.destination, action: /Action.destination) {
      EmptyReducer()
        .ifCaseLet(/State.Destination.players, action: /Action.Destination.players) { Players() }
        .ifCaseLet(/State.Destination.sports, action: /Action.Destination.sports) { Sports() }
        .ifCaseLet(/State.Destination.activities, action: /Action.Destination.activities) { Activities() }
        .ifCaseLet(/State.Destination.settings, action: /Action.Destination.settings) { Settings() }
        .ifCaseLet(/State.Destination.newSession, action: /Action.Destination.newSession) { NewSession() }
        .ifCaseLet(/State.Destination.sessionDetails, action: /Action.Destination.sessionDetails) { SessionDetails() }
        .ifCaseLet(/State.Destination.sessions, action: /Action.Destination.sessions) { Sessions() }
    }
    ._printChanges()
  }
}

// MARK: - SwiftUI

struct HomeView: View {
  let store: StoreOf<Home>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        List {
          Section {
            PlayersNavigationLink(store: store)
            SportsNavigationLink(store: store)
            ActivitiesNavigationLink(store: store)
            SettingsNavigationLink(store: store)
          }
          .font(.title3)
          
          Section(header: HStack {
            Text("Recent Sessions")
              .font(.title2)
              .bold()
              .foregroundColor(.primary)
            Spacer()
            SeeAll(store: store)
          }.padding(.top, 16)) {
            ForEachStore(store.scope(
              state: \.recentSessions,
              action: Home.Action.recentSessions
            )) { childStore in
              RecentSessionNavigationLink(
                store: store,
                childStore: childStore
              )
            }
          }
        }
        .task { viewStore.send(.task) }
        .refreshable { viewStore.send(.task) }
        .listStyle(.plain)
        .searchable(text: viewStore.binding(\.$search))
        .toolbar {
          ToolbarItemGroup(placement: .bottomBar) {
            HStack {
              Button(action: { viewStore.send(.toggleIsFiltering) }) {
                Image(
                  systemName: viewStore.isFiltering
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle"
                )
              }
              Spacer()
              Button(action: { viewStore.send(.newSessionButtonTapped) }) {
                Image(systemName: "square.and.pencil")
              }
            }
          }
        }
        .sheet(
          isPresented: viewStore.binding(
            get: { CasePath.extract(/Home.State.Destination.newSession)(from: $0.destination) != nil },
            send: { Home.Action.setDestination($0 ? .newSession(.init()) : nil) }
          ),
          content: {
            IfLetStore(store
              .scope(state: \.destination, action: Home.Action.destination)
              .scope(state: /Home.State.Destination.newSession, action: Home.Action.Destination.newSession)
            ) { NewSessionView(store: $0) }
          }
        )
        .sheet(
          isPresented: viewStore.binding(
            get: { CasePath.extract(/Home.State.Destination.account)(from: $0.destination) != nil },
            send: { Home.Action.setDestination($0 ? .account(.init(profile: viewStore.profile)) : nil) }
          ),
          content: {
            IfLetStore(store
              .scope(state: \.destination, action: Home.Action.destination)
              .scope(state: /Home.State.Destination.account, action: Home.Action.Destination.account)
            ) { AccountView(store: $0) }
          }
        )
        .navigationTitle("PocketRadar")
        .toolbar {
          Button(action: { viewStore.send(.profileButtonTapped)}) {
            SmallProfileView(store: store.scope(
              state: \.profile,
              action: Home.Action.profile
            ))
          }
        }
      }
    }
  }
}

private struct PlayersNavigationLink: View {
  let store: StoreOf<Home>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationLink(
        destination: IfLetStore(store
          .scope(state: \.destination, action: Home.Action.destination)
          .scope(state: /Home.State.Destination.players, action: Home.Action.Destination.players)
        ) { PlayersView(store: $0) },
        tag: true,
        selection: viewStore.binding(
          get: { _ in CasePath.extract(/Home.State.Destination.players)(from: viewStore.destination) != nil },
          send: { Home.Action.setDestination(.players(Players.State())) }()
        ),
        label: {
          Label("Players", systemImage: "person.2")
        }
      )
      .listRowSeparator(.hidden, edges: .top)
    }
  }
}
private struct SportsNavigationLink: View {
  let store: StoreOf<Home>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationLink(
        destination: IfLetStore(store
          .scope(state: \.destination, action: Home.Action.destination)
          .scope(state: /Home.State.Destination.sports, action: Home.Action.Destination.sports)
        ) { SportsView(store: $0) },
        tag: true,
        selection: viewStore.binding(
          get: { _ in CasePath.extract(/Home.State.Destination.sports)(from: viewStore.destination) != nil },
          send: { Home.Action.setDestination(.sports(Sports.State())) }()
        ),
        label: {
          Label("Sports", systemImage: "baseball")
        }
      )
    }
  }
}
private struct ActivitiesNavigationLink: View {
  let store: StoreOf<Home>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationLink(
        destination: IfLetStore(store
          .scope(state: \.destination, action: Home.Action.destination)
          .scope(state: /Home.State.Destination.activities, action: Home.Action.Destination.activities)
        ) { ActivitiesView(store: $0) },
        tag: true,
        selection: viewStore.binding(
          get: { _ in CasePath.extract(/Home.State.Destination.activities)(from: viewStore.destination) != nil },
          send: { Home.Action.setDestination(.activities(Activities.State())) }()
        ),
        label: {
          Label("Activities", systemImage: "list.clipboard")
        }
      )
    }
  }
}
private struct SettingsNavigationLink: View {
  let store: StoreOf<Home>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationLink(
        destination: IfLetStore(store
          .scope(state: \.destination, action: Home.Action.destination)
          .scope(state: /Home.State.Destination.settings, action: Home.Action.Destination.settings)
        ) { SettingsView(store: $0) },
        tag: true,
        selection: viewStore.binding(
          get: { _ in CasePath.extract(/Home.State.Destination.settings)(from: viewStore.destination) != nil },
          send: { Home.Action.setDestination(.settings(Settings.State())) }()
        ),
        label: {
          Label("Settings", systemImage: "gear")
        }
      )
    }
  }
}

private struct RecentSessionNavigationLink: View {
  let store: StoreOf<Home>
  let childStore: StoreOf<SessionRow>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      WithViewStore(childStore) { childViewStore in
        NavigationLink(
          destination: IfLetStore(store
            .scope(state: \.destination, action: Home.Action.destination)
            .scope(state: /Home.State.Destination.sessionDetails, action: Home.Action.Destination.sessionDetails)
          ) { SessionDetailsView(store: $0) },
          tag: childViewStore.id,
          selection: viewStore.binding(
            get: { CasePath.extract(/Home.State.Destination.sessionDetails)(from: $0.destination)?.session.id },
            send: { Home.Action.setDestination(viewStore
              .recentSessions[id: childViewStore.id].flatMap({
                Home.State.Destination.sessionDetails(SessionDetails.State(session: $0.session))
              })
            )}()
          ),
          label: {
            SessionRowView(store: childStore)
          }
        )
        .buttonStyle(.plain)
        //.listRowBackground(EmptyView())
      }
    }
  }
}

private struct SeeAll: View {
  let store: StoreOf<Home>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationLink(
        destination: IfLetStore(store
          .scope(state: \.destination, action: Home.Action.destination)
          .scope(state: /Home.State.Destination.sessions, action: Home.Action.Destination.sessions)
        ) { SessionsView(store: $0) },
        tag: true,
        selection: viewStore.binding(
          get: { _ in CasePath.extract(/Home.State.Destination.sessions)(from: viewStore.destination) != nil },
          send: { Home.Action.setDestination(.sessions(Sessions.State())) }()
        ),
        label: {
          Text("See All")
        }
      )
    }
  }
}

// MARK: - SwiftUI Previews

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView(
      store: Store(
        initialState: Home.State(),
        reducer: Home()
      )
    )
  }
}
