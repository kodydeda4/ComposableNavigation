import ComposableArchitecture
import SwiftUI

struct Root: ReducerProtocol {
  struct State: Equatable {
    var recentSessions = IdentifiedArrayOf<SessionRow.State>()
    var destination: Destination?
    
    enum Destination: Equatable {
      case sessionDetails(SessionDetails.State)
      case newSession(NewSession.State)
    }
  }
  
  enum Action: Equatable {
    case task
    case taskResponse(TaskResult<[LocalDatabaseClient.Session]>)
    case newSessionButtonTapped
    case setDestination(State.Destination?)
    case recentSessions(id: SessionRow.State.ID, action: SessionRow.Action)
    case destination(Destination)
    
    enum Destination: Equatable {
      case sessionDetails(SessionDetails.Action)
      case newSession(NewSession.Action)
    }
  }
  
  @Dependency(\.database) var database
  
  var body: some ReducerProtocol<State, Action> {
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
    }
    ._printChanges()
  }
}

extension Root.State {
  struct Row: Equatable, Identifiable {
    var id: LocalDatabaseClient.Session.ID { model.id }
    var model: LocalDatabaseClient.Session
  }
}


// MARK: - SwiftUI

struct RootView: View {
  let store: StoreOf<Root>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        List {
          Section("Recent Sessions") {
            ForEachStore(store.scope(
              state: \.recentSessions,
              action: Root.Action.recentSessions
            )) { childStore in
              RowView(
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
            Button(action: { viewStore.send(.newSessionButtonTapped) }) {
              Image(systemName: "square.and.pencil")
            }
          }
        }
        .sheet(
          isPresented: viewStore.binding(
            get: {
              CasePath.extract(/Root.State.Destination.newSession)(from: $0.destination) != nil
            },
            send: {
              Root.Action.setDestination($0 ? .newSession(.init()) : nil)
            }
          ),
          content: {
            IfLetStore(
              store
                .scope(
                  state: \.destination,
                  action: Root.Action.destination
                )
                .scope(
                  state: /Root.State.Destination.newSession,
                  action: Root.Action.Destination.newSession
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

private struct RowView: View {
  let store: StoreOf<Root>
  let childStore: StoreOf<SessionRow>

  var body: some View {
    WithViewStore(store) { viewStore in
      WithViewStore(childStore) { childViewStore in
        NavigationLink(
          destination: IfLetStore(
            store
              .scope(
                state: \.destination,
                action: Root.Action.destination
              )
              .scope(
                state: /Root.State.Destination.sessionDetails,
                action: Root.Action.Destination.sessionDetails
              ),
            then: SessionDetailsView.init),
          tag: childViewStore.id,
          selection: viewStore.binding(
            get: {
              CasePath.extract(/Root.State.Destination.sessionDetails)(from: $0.destination)?.session.id
            },
            send: {
              Root.Action.setDestination(
                viewStore.recentSessions[id: childViewStore.id].flatMap({ Root.State.Destination.sessionDetails(SessionDetails.State(session: $0.session)) })
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


// MARK: - SwiftUI Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView(
      store: Store(
        initialState: Root.State(),
        reducer: Root()
      )
    )
  }
}
