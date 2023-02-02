import ComposableArchitecture
import SwiftUI

struct Sessions: ReducerProtocol {
  struct State: Equatable {
    var recentSessions = IdentifiedArrayOf<SessionRow.State>()
    var destination: Destination?
    @BindingState var search = String()
    
    enum Destination: Equatable {
      case sessionDetails(SessionDetails.State)
    }
  }
  
  enum Action: BindableAction, Equatable {
    case task
    case taskResponse(TaskResult<[LocalDatabaseClient.Session]>)
    case recentSessions(id: SessionRow.State.ID, action: SessionRow.Action)
    case setDestination(State.Destination?)
    case binding(BindingAction<State>)
    case destination(Destination)
    
    enum Destination: Equatable {
      case sessionDetails(SessionDetails.Action)
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
        
      case .recentSessions:
        return .none
        
      case let .setDestination(value):
        state.destination = value
        return .none
        
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
        .ifCaseLet(/State.Destination.sessionDetails, action: /Action.Destination.sessionDetails) {
          SessionDetails()
        }
    }
    ._printChanges()
  }
}

// MARK: - SwiftUI

struct SessionsView: View {
  let store: StoreOf<Sessions>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      List {
        Section("Sessions") {
          ForEachStore(store.scope(
            state: \.recentSessions,
            action: Sessions.Action.recentSessions
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
      .navigationTitle("Sessions")
      .searchable(text: viewStore.binding(\.$search))
    }
  }
}

private struct RowView: View {
  let store: StoreOf<Sessions>
  let childStore: StoreOf<SessionRow>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      WithViewStore(childStore) { childViewStore in
        NavigationLink(
          destination: IfLetStore(
            store
              .scope(
                state: \.destination,
                action: Sessions.Action.destination
              )
              .scope(
                state: /Sessions.State.Destination.sessionDetails,
                action: Sessions.Action.Destination.sessionDetails
              ),
            then: SessionDetailsView.init),
          tag: childViewStore.id,
          selection: viewStore.binding(
            get: {
              CasePath.extract(/Sessions.State.Destination.sessionDetails)(from: $0.destination)?.session.id
            },
            send: {
              Sessions.Action.setDestination(
                viewStore.recentSessions[id: childViewStore.id].flatMap({ Sessions.State.Destination.sessionDetails(SessionDetails.State(session: $0.session)) })
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

struct SessionsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SessionsView(
        store: Store(
          initialState: Sessions.State(),
          reducer: Sessions()
        )
      )
    }
  }
}
