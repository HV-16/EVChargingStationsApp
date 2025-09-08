//
//  MockPersistenceController.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

@testable import EVChargingStationsApp

final class MockPersistence: PersistenceProtocol {
    var savedStations: [ChargingStation] = []
    var fetchedStations: [ChargingStation] = []

    func saveStations(_ stations: [ChargingStation]) {
        // simple overwrite behaviour
        savedStations = stations
    }

    func fetchStations() -> [ChargingStation] {
        return fetchedStations
    }
}
