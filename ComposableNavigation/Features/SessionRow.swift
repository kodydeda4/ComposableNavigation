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
            //try await Task.sleep(for: .seconds(5))
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

private extension SessionRow.State {
  var maxSpeed: Double? {
    measurements.map(\.measurement.value).max()
  }
  var avgSpeed: Double? {
    let total = measurements.map(\.measurement.value).reduce(0.0, +)
    let count = Double(measurements.count)
    
    if total == 0 {
      return nil
    } else {
      return total / count
    }
  }
}


// MARK: - SwiftUI

struct SessionRowView: View {
  let store: StoreOf<SessionRow>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      HStack {
        
        Text("\(viewStore.measurements.count)")
          .frame(width: 40, height: 40)
          .background(Color(.systemGray4))
          .clipShape(Circle())
          
        VStack(alignment: .leading, spacing: 2) {
          HStack {
            Text("\(viewStore.id.rawValue.description.prefix(12).description)")
              .lineLimit(1)
              //.font(.subheadline)
              .bold()
            
            Spacer()
            
            Text("\(Date().formatted())")
              .lineLimit(1)
              //.font(.subheadline)
              .foregroundColor(.secondary)
          }
          HStack {
            VStack {
              Text("MAX (MPH)")
                .font(.footnote)
                .foregroundColor(.secondary)
              Text("\(viewStore.maxSpeed?.formattedDescription ?? "--")")
                .foregroundColor(.accentColor)
                //.font(.caption)
            }
            .frame(maxWidth: .infinity)
            
            VStack {
              Text("AVG (MPH)")
                .font(.footnote)
                .foregroundColor(.secondary)
              Text("\(viewStore.avgSpeed?.formattedDescription ?? "--")")
                .foregroundColor(.primary)
                //.font(.caption)
            }
            .frame(maxWidth: .infinity)
            
            VStack {
              Text("COUNT")
                .font(.footnote)
                .foregroundColor(.secondary)
              Text("\(viewStore.measurements.count)")
                .foregroundColor(.primary)
                //.font(.caption)
            }
            .frame(maxWidth: .infinity)
          }
          
          //        Spacer()
          //        ProgressView()
          //          .opacity(viewStore.isLoading ? 1 : 0)
        }
      }
      .task { viewStore.send(.task) }
      .padding(.vertical, 8)
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
