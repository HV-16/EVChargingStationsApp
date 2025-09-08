//
//  MockLocationProvider.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import CoreLocation
import Foundation
@testable import EVChargingStationsApp

final class MockLocationProvider: LocationProvider {
    var coordinateToReturn: CLLocationCoordinate2D?
    var errorToThrow: Error?

    func currentLocation() async throws -> CLLocationCoordinate2D {
        if let e = errorToThrow { throw e }
        if let coord = coordinateToReturn { return coord }
        // default fallback
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}
