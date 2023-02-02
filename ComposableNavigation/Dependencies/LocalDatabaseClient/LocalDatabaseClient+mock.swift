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
      let sessionID = LocalDatabaseClient.Session.ID()
      self.measurements = .init(uniqueElements: (1..<10).map { _ in
        LocalDatabaseClient.Measurement(
          id: .init(),
          sessionID: sessionID,
          measurement: .init(
            value: Double.random(in: 1..<100),
            unit: .milesPerHour
          )
        )
      })
      self.sessions = .init(uniqueElements: [
        .init(id: sessionID, measurementIDs: measurements.map(\.id))
      ])
    }
  }
}
