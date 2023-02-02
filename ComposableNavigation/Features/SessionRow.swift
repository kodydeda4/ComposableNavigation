import SwiftUI
import ComposableArchitecture

struct SessionRow: ReducerProtocol {
  struct State: Identifiable, Equatable {
    var id: LocalDatabaseClient.Session.ID { session.id }
    var session: LocalDatabaseClient.Session
    var measurements = [LocalDatabaseClient.Measurement]()
    var isLoading = false
  }
  
  enum Action: Equatable {
    case task
    case taskResponse(TaskResult<[LocalDatabaseClient.Measurement]>)
  }
  
  @Dependency(\.database) var database
  
  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
        
      case .task:
        state.isLoading = true
        return .task { [measurementIDs = state.session.measurementIDs] in
          await .taskResponse(TaskResult {
            var rv = [LocalDatabaseClient.Measurement]()
            for value in measurementIDs {
              if let measurement = try await self.database.getMeasurement(value) {
                rv.append(measurement)
              }
            }
            try await Task.sleep(for: .seconds(5))
            return rv
          })
        }
        
      case let .taskResponse(.success(value)):
        state.isLoading = false
        state.measurements = value
        return .none
        
      case .taskResponse(.failure):
        state.isLoading = false
        return .none
        
      }
    }
  }
}


// MARK: - SwiftUI

struct SessionRowView: View {
  let store: StoreOf<SessionRow>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      HStack {
        Text("\(viewStore.id.rawValue.description)")
          .lineLimit(1)
        Spacer()
        ProgressView()
          .opacity(viewStore.isLoading ? 1 : 0)
      }
      .task { viewStore.send(.task) }
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

struct SessionRowView_Previews: PreviewProvider {
  private static let sessionID = LocalDatabaseClient.Session.ID()
  
  static var previews: some View {
    NavigationStack {
      List {
        SessionRowView(store: .init(
          initialState: SessionRow.State(
            session: .init(
              id: sessionID,
              measurementIDs: []
            )
          ),
          reducer: SessionRow()
        ))
      }
      .navigationTitle("Preview")
    }
  }
}
