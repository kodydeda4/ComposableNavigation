import SwiftUI
import ComposableArchitecture

struct NewSession: ReducerProtocol {
  struct State: Equatable {
    var session = LocalDatabaseClient.Session(id: .init(), measurementIDs: [])
    var measurements = [LocalDatabaseClient.Measurement]()
    var destination: Destination?

    enum Destination: Equatable {
      case saving
      case saveErrorAlert(AlertState<Action>)
    }
  }
  
  enum Action: Equatable {
    case task
    case taskResponse(TaskResult<RadarClient.Speed>)
    case cancelStream
    case cancelButtonTapped
    case doneButtonTapped
    case save
    case saveResponse(TaskResult<String>)
    case alertDismissed
    case dismiss
  }
  
  private enum CancelID {}
  @Dependency(\.database) var database
  @Dependency(\.radar) var radar
  
  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
        
      case .task:
        return .run { send in
          for await value in try await self.radar.stream() {
            await send(.taskResponse(TaskResult { value }))
          }
        }
        .cancellable(id: CancelID.self, cancelInFlight: false)
        
      case let .taskResponse(.success(value)):
        let newMeasurement = LocalDatabaseClient.Measurement(
          id: .init(),
          sessionID: state.session.id,
          measurement: value.measurement
        )
        state.measurements.append(newMeasurement)
        state.session.measurementIDs.append(newMeasurement.id)
        return .send(.save)
        
      case .taskResponse(.failure):
        return .none
        
      case .cancelStream:
        return .cancel(id: CancelID.self)

      case .cancelButtonTapped:
        return .send(.dismiss)
        
      case .doneButtonTapped:
        return .run { send in
          await send(.cancelStream)
          await send(.dismiss)
        }
      
      case .save:
        state.destination = .saving
        return .task { [
          session = state.session,
          latestMeasurement = state.measurements.last
        ] in
          await .saveResponse(TaskResult {
            //try await Task.sleep(for: .seconds(1))
            if let latestMeasurement = latestMeasurement {
              try await self.database.upsertSession(session)
              try await self.database.upsertMeasurement(latestMeasurement)
              return "success"
            } else {
              struct Failure: Error, Equatable {}
              throw Failure()
            }
          })
        }

      case .saveResponse(.success):
        state.destination = nil
        return .none
        
      case .saveResponse(.failure):
        state.destination = .saveErrorAlert(AlertState {
          TextState("Error saving")
        })
        return .none
        
      case .dismiss:
        return .none
        
      case .alertDismissed:
        state.destination = nil
        return .none
      }
    }
  }
}


// MARK: - SwiftUI

struct NewSessionView: View {
  let store: StoreOf<NewSession>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        List {
          Section("Speeds") {
            ForEach(viewStore.measurements) { measurement in
              Text(measurement.measurement.value.formattedDescription)
              +
              Text(" \(measurement.measurement.unit.symbol)")
            }
          }
        }
        .task { viewStore.send(.task) }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("New Session")
        .alert(
          self.store.scope(state: {
            CasePath.extract(/NewSession.State.Destination.saveErrorAlert)(from: $0.destination)
          }),
          dismiss: .alertDismissed
        )
        .toolbar {
          ToolbarItemGroup(placement: .cancellationAction) {
            Button("Cancel") {
              viewStore.send(.cancelButtonTapped)
            }
          }
          ToolbarItemGroup(placement: .confirmationAction) {
            Button("Done") {
              viewStore.send(.doneButtonTapped)
            }
          }
        }
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

struct NewSessionView_Previews: PreviewProvider {
  static var previews: some View {
    NewSessionView(store: .init(
      initialState: NewSession.State(
//        destination: .saveErrorAlert(.init {
//          .init("Error saving")
//        })
      ),
      reducer: NewSession()
    ))
  }
}
