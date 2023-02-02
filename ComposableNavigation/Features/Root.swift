import ComposableArchitecture
import SwiftUI

struct Root: ReducerProtocol {
  struct State: Equatable {
    var rows = IdentifiedArrayOf<Row>()
    var destination: Destination.State?
    
    struct Row: Equatable, Identifiable {
      var id: LocalDatabaseClient.Session.ID { model.id }
      var model: LocalDatabaseClient.Session
    }
  }
  
  enum Action: Equatable {
    case task
    case taskResponse(TaskResult<[LocalDatabaseClient.Session]>)
    case setDestination(Destination.State?)
    case newSessionButtonTapped
    
    
    case none
    case destination(Destination.Action)
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
        state.rows = .init(uniqueElements: values.map {
          State.Row(model: $0)
        })
        return .none
        
      case .taskResponse(.failure):
        return .none
        
      case let .setDestination(value):
        state.destination = value
        return .none
        
      case .newSessionButtonTapped:
        state.destination = .newSession(NewSession.State())
        return .none
        
      case .destination(.newSession(.dismiss)):
        state.destination = nil
        return .send(.task)
        
      case .destination:
        return .none
        
      case .none:
        return .none
        
      }
    }
    .ifLet(\.destination, action: /Action.destination) {
      Destination()
    }
    ._printChanges()
  }
}

extension Root {
  struct Destination: ReducerProtocol {
    enum State: Equatable {
      case sessionDetails(SessionDetails.State)
      case newSession(NewSession.State)
    }
    
    enum Action: Equatable {
      case sessionDetails(SessionDetails.Action)
      case newSession(NewSession.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
      EmptyReducer()
        .ifCaseLet(/State.newSession, action: /Action.newSession) {
          NewSession()
        }
        .ifCaseLet(/State.sessionDetails, action: /Action.sessionDetails) {
          SessionDetails()
        }
    }
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
            ForEach(viewStore.rows) { row in
              RowView(store: store, row: row)
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
              CasePath.extract(/Root.Destination.State.newSession)(from: $0.destination) != nil
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
                  state: /Root.Destination.State.newSession,
                  action: Root.Destination.Action.newSession
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
  let row: Root.State.Row
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationLink(
        destination: IfLetStore(
          store
            .scope(
              state: \.destination,
              action: Root.Action.destination
            )
            .scope(
              state: /Root.Destination.State.sessionDetails,
              action: Root.Destination.Action.sessionDetails
            ),
          then: SessionDetailsView.init),
        tag: row.id,
        selection: viewStore.binding(
          get: {
            CasePath.extract(/Root.Destination.State.sessionDetails)(from: $0.destination)?.session.id
          },
          send: {
            Root.Action.setDestination(
              viewStore.rows[id: row.id].flatMap({ Root.Destination.State.sessionDetails(SessionDetails.State(session: $0.model)) })
            )
          }()
        ),
        label: {
          Text("\(row.id.rawValue.description)")
            .lineLimit(1)
          
        }
      )
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
