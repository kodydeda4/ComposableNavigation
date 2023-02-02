import Foundation
import ComposableArchitecture

extension RadarClient {
  static var mock: Self {
    let radar = RadarMock()
    
    return Self(
      connect: {
        try await radar.connect()
        return await radar.model
      },
      stream: {
        AsyncStream { continuation in
          Task {
            while true {
              continuation.yield(RadarClient.Speed(
                id: .init(),
                measurement: .init(
                  value: Double.random(in: 1..<100),
                  unit: .milesPerHour
                ))
              )
              try await Task.sleep(nanoseconds: NSEC_PER_SEC * 3)
            }
          }
        }
      }
    )
  }
}

// MARK: - Private

private actor RadarMock {
  var model = RadarClient.Radar(
    id: .init(),
    isConnected: false
  )
  
  func connect() throws {
    self.model.isConnected.toggle()
  }
}

