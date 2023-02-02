import SwiftUI
import ComposableArchitecture

struct SessionDetails: ReducerProtocol {
  struct State: Equatable {
    var session: LocalDatabaseClient.Session
    var measurements = [LocalDatabaseClient.Measurement]()
    @BindingState var search = String()
  }
  
  enum Action: BindableAction, Equatable {
    case task
    case taskResponse(TaskResult<[LocalDatabaseClient.Measurement]>)
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.database) var database
  
  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
        
      case .task:
        return .task { [measurementIDs = state.session.measurementIDs] in
          await .taskResponse(TaskResult {
            var rv = [LocalDatabaseClient.Measurement]()
            for value in measurementIDs {
              if let measurement = try await self.database.getMeasurement(value) {
                rv.append(measurement)
              }
            }
            return rv
          })
        }
        
      case let .taskResponse(.success(value)):
        state.measurements = value
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

struct SessionDetailsView: View {
  let store: StoreOf<SessionDetails>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        List {
          ForEach(viewStore.measurements) { measurement in
            Text(measurement.measurement.value.formattedDescription)
            +
            Text(" \(measurement.measurement.unit.symbol)")
          }
        }
        .task { viewStore.send(.task) }
        .navigationTitle("\(viewStore.session.id.description)")
        .searchable(
          text: viewStore.binding(\.$search),
          placement: .navigationBarDrawer(displayMode: .always)
        )
      }
    }
  }
}

private extension Double {
  var formattedDescription: String {
    let numberFormatter: NumberFormatter = {
      let rv = NumberFormatter()
      rv.numberStyle = .decimal
      rv.maximumFractionDigits = 1
      return rv
    }()
    return numberFormatter.string(from: .init(value: self))!
  }
}


// MARK: - SwiftUI Previews

struct SessionDetailsView_Previews: PreviewProvider {
  private static let sessionID = LocalDatabaseClient.Session.ID()
  static var previews: some View {
    SessionDetailsView(store: .init(
      initialState: SessionDetails.State(
        session: .init(
          id: sessionID,
          measurementIDs: []
        )
      ),
      reducer: SessionDetails()
    ))
  }
}
