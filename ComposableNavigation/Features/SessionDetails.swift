import SwiftUI
import ComposableArchitecture

struct SessionDetails: ReducerProtocol {
  struct State: Equatable {
    var session: LocalDatabaseClient.Session
    var measurements = [LocalDatabaseClient.Measurement]()
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
          ForEach(viewStore.measurements.sorted()) { measurement in
            Text(measurement.measurement.value.formattedDescription)
            +
            Text(" \(measurement.measurement.unit.symbol)")
          }
        }
        .task { viewStore.send(.task) }
        .navigationTitle("\(viewStore.session.id.rawValue.description.prefix(16).description)")
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
  static let measurementID = LocalDatabaseClient.Measurement.ID(rawValue: .init(
    uuidString: "00000000-0000-0000-0000-000000000001"
  )!)
  static let sessionID = LocalDatabaseClient.Session.ID(rawValue: .init(
    uuidString: "00000000-0000-0000-0000-000000000000"
  )!)

  static var previews: some View {
    SessionDetailsView(store: .init(
      initialState: SessionDetails.State(
        session: .init(
          id: sessionID,
          measurementIDs: [
            measurementID
          ]
        )
      ),
      reducer: SessionDetails()
    ))
  }
}
