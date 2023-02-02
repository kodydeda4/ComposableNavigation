import ComposableArchitecture
import SwiftUI

struct Home: ReducerProtocol {
  struct State: Equatable {
    var recentSessions = IdentifiedArrayOf<SessionRow.State>()
    var destination: Destination?
    @BindingState var isFiltering = false
    
    enum Destination: Equatable {
      case sessionDetails(SessionDetails.State)
      case newSession(NewSession.State)
      case sessions(Sessions.State)
    }
  }
  
  enum Action: BindableAction, Equatable {
    case task
    case taskResponse(TaskResult<[LocalDatabaseClient.Session]>)
    case seeAllButtonTapped
    case toggleIsFiltering
    case newSessionButtonTapped
    case binding(BindingAction<State>)
    case setDestination(State.Destination?)
    case recentSessions(id: SessionRow.State.ID, action: SessionRow.Action)
    case destination(Destination)
    
    enum Destination: Equatable {
      case sessionDetails(SessionDetails.Action)
      case newSession(NewSession.Action)
      case sessions(Sessions.Action)
    }
  }
  
  @Dependency(\.database) var database
  
  var body: some ReducerProtocol<State, Action> {
    BindingReducer()
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
        
      case .seeAllButtonTapped:
        state.destination = .sessions(Sessions.State())
        return .none
      
      case .toggleIsFiltering:
        state.isFiltering.toggle()
        return .none
        
      case .newSessionButtonTapped:
        state.destination = .newSession(NewSession.State())
        return .none
        
      case .recentSessions:
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
        .ifCaseLet(/State.Destination.newSession, action: /Action.Destination.newSession) {
          NewSession()
        }
        .ifCaseLet(/State.Destination.sessionDetails, action: /Action.Destination.sessionDetails) {
          SessionDetails()
        }
        .ifCaseLet(/State.Destination.sessions, action: /Action.Destination.sessions) {
          Sessions()
        }
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
          Section(header: HStack {
            Text("Recent Sessions")
            Spacer()
            SeeAll(store: store)
          }) {
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
            get: {
              CasePath.extract(/Home.State.Destination.newSession)(from: $0.destination) != nil
            },
            send: {
              Home.Action.setDestination($0 ? .newSession(.init()) : nil)
            }
          ),
          content: {
            IfLetStore(
              store
                .scope(
                  state: \.destination,
                  action: Home.Action.destination
                )
                .scope(
                  state: /Home.State.Destination.newSession,
                  action: Home.Action.Destination.newSession
                ),
              then: NewSessionView.init
            )
          }
        )
        .navigationTitle("PocketRadar")
      }
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
                                  ,then: SessionDetailsView.init),
          tag: childViewStore.id,
          selection: viewStore.binding(
            get: {
              CasePath.extract(/Home.State.Destination.sessionDetails)(from: $0.destination)?.session.id
            },
            send: {
              Home.Action
                .setDestination(
                  viewStore.recentSessions[id: childViewStore.id]
                    .flatMap({
                      Home.State.Destination.sessionDetails(
                        SessionDetails.State(session: $0.session)
                      )
                    })
                )
            }()
          ),
          label: {
            SessionRowView(store: childStore)
          }
        )
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
                                , then: SessionsView.init),
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
