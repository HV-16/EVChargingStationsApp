//
//  OpenChargeMapServiceMock.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

@testable import EVChargingStationsApp

final class MockService: OpenChargeMapServiceProtocol {
    var nextStations: [ChargingStation] = []
    var errorToThrow: Error?

    func fetchStations(latitude: Double?, longitude: Double?, distanceKm: Double?, maxResults: Int) async throws -> [ChargingStation] {
        if let e = errorToThrow { throw e }
        return nextStations
    }
}
