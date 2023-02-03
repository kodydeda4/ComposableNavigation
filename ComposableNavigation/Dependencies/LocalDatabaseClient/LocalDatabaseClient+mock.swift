import Foundation
import ComposableArchitecture

extension LocalDatabaseClient {
  static var mock: Self {
    let db = DatabaseMock()
    
    return Self(
      /// `Session`
      getSessions: {
        await db.sessions.elements
      },
      upsertSession: { session in
        await db.upsert(session)
      },
      getMeasurement: { measurementID in
        await db.measurements[id: measurementID]
      },
      upsertMeasurement: { measurement in
        await db.upsert(measurement)
      }
    )
  }
}

// MARK: - Private
private extension LocalDatabaseClient {
  private actor DatabaseMock {
    var sessions: IdentifiedArrayOf<Session>
    var measurements: IdentifiedArrayOf<Measurement>
    
    ///`Session`
    func upsert(_ session: LocalDatabaseClient.Session) {
      self.sessions.updateOrAppend(session)
    }

    ///`Measurement`
    func upsert(_ measurement: LocalDatabaseClient.Measurement) {
      self.measurements.updateOrAppend(measurement)
    }

    init() {
      let measurementID = LocalDatabaseClient.Measurement.ID(rawValue: .init(
        uuidString: "00000000-0000-0000-0000-000000000001"
      )!)
      let sessionID = LocalDatabaseClient.Session.ID(rawValue: .init(
        uuidString: "00000000-0000-0000-0000-000000000000"
      )!)
      
      self.measurements = .init(uniqueElements: [
        LocalDatabaseClient.Measurement(
          id: measurementID,
          sessionID: sessionID,
          measurement: .init(
            value: Double.random(in: 1..<100),
            unit: .milesPerHour
          )
        )
      ])
      self.sessions = .init(uniqueElements: [
        .init(id: sessionID, measurementIDs: measurements.map(\.id))
      ])
    }
  }
}
