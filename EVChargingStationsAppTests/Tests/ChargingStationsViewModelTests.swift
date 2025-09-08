//
//  ChargingStationsViewModelTests.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation
import CoreLocation
import Testing
@testable import EVChargingStationsApp

@Suite("ChargingStationsViewModel suite")
struct ChargingStationsViewModelTests {

    private func makeSampleStation(id: Int = 1, title: String = "Station") -> ChargingStation {
        let addressInfo = AddressInfo(
            id: nil,
            title: title,
            addressLine1: "line1",
            addressLine2: nil,
            town: "Town",
            stateOrProvince: "ST",
            postcode: "000",
            latitude: 1.0,
            longitude: 2.0,
            accessComments: nil,
            country: nil
        )
        return ChargingStation(
            id: id,
            uuid: nil,
            addressInfo: addressInfo,
            connections: nil
        )
    }

    private func waitForIdle(vm: ChargingStationsViewModel, timeout: TimeInterval = 5.0) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            let loading = await MainActor.run { vm.isLoading }
            if !loading { break }
            if Date() > deadline { break }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    @Test("Online fetch using location saves results to persistence")
    func testFetchChargingStations_useLocation_onlineSuccess() async throws {
        let mockService = MockService()
        let station = makeSampleStation(id: 101, title: "Online Station")
        mockService.nextStations = [station]

        let mockLocation = MockLocationProvider()
        mockLocation.coordinateToReturn = CLLocationCoordinate2D(latitude: 1.0, longitude: 2.0)

        let persistence = MockPersistence()

        let vm = await MainActor.run {
            ChargingStationsViewModel(service: mockService, locationProvider: mockLocation, persistence: persistence)
        }

        await vm.fetchChargingStations(useLocation: true)

        try await waitForIdle(vm: vm)

        await MainActor.run {
            #expect(vm.chargingStations.count == 1)
            #expect(vm.chargingStations.first?.id == 101)
            #expect(persistence.savedStations.count == 1)
            #expect(persistence.savedStations.first?.id == 101)
        }
    }

    @Test("Location denied falls back to non-location fetch and saves results")
    func testFetchChargingStations_locationDenied() async throws {
        let mockService = MockService()
        let fallbackStation = makeSampleStation(id: 202, title: "Fallback Station")
        mockService.nextStations = [fallbackStation]

        let mockLocation = MockLocationProvider()
        mockLocation.errorToThrow = LocationError.authorizationDenied

        let persistence = MockPersistence()

        let vm = await MainActor.run {
            ChargingStationsViewModel(service: mockService, locationProvider: mockLocation, persistence: persistence)
        }

        await vm.fetchChargingStations(useLocation: true)

        try await waitForIdle(vm: vm)

        await MainActor.run {
            #expect(vm.chargingStations.count == 1)
            #expect(vm.chargingStations.first?.id == 202)
            #expect(persistence.savedStations.count == 1)
            #expect(persistence.savedStations.first?.id == 202)
        }
    }

    @Test("Network failure -> fallback to cache when cached exists")
    func testFetchChargingStations_networkFailureUsesCache() async throws {
        let mockService = MockService()
        mockService.errorToThrow = URLError(.notConnectedToInternet)

        let mockLocation = MockLocationProvider()
        mockLocation.coordinateToReturn = CLLocationCoordinate2D(latitude: 1.0, longitude: 2.0)

        let cachedStation = makeSampleStation(id: 303, title: "Cached Station")
        let persistence = MockPersistence()
        // pre-populate the data that fetchStations() returns
        persistence.fetchedStations = [cachedStation]

        let vm = await MainActor.run {
            ChargingStationsViewModel(service: mockService, locationProvider: mockLocation, persistence: persistence)
        }

        await vm.fetchChargingStations(useLocation: true)

        try await waitForIdle(vm: vm)

        await MainActor.run {
            #expect(vm.chargingStations.count == 1)
            #expect(vm.chargingStations.first?.id == 303)
            #expect(vm.isOffline == true)
        }
    }

    @Test("Network failure + no cache -> error message shown")
    func testFetchChargingStations_networkFailureNoCacheShowsError() async throws {
        let mockService = MockService()
        mockService.errorToThrow = URLError(.notConnectedToInternet)

        let mockLocation = MockLocationProvider()
        mockLocation.coordinateToReturn = CLLocationCoordinate2D(latitude: 1.0, longitude: 2.0)

        let persistence = MockPersistence()

        let vm = await MainActor.run {
            ChargingStationsViewModel(service: mockService, locationProvider: mockLocation, persistence: persistence)
        }

        await vm.fetchChargingStations(useLocation: true)

        try await waitForIdle(vm: vm)

        await MainActor.run {
            #expect(vm.chargingStations.isEmpty)
            #expect((vm.errorMessage ?? "").isEmpty == false)
        }
    }

    // MARK: - Non-location (generic) fetch tests

    @Test("Generic (no-location) fetch succeeds and saves results")
    func testFetchChargingStations_noLocation_onlineSuccess() async throws {
        let mockService = MockService()
        let station = makeSampleStation(id: 401, title: "Generic Station")
        mockService.nextStations = [station]

        let mockLocation = MockLocationProvider() // unused
        let persistence = MockPersistence()

        let vm = await MainActor.run {
            ChargingStationsViewModel(service: mockService, locationProvider: mockLocation, persistence: persistence)
        }

        await vm.fetchChargingStations(useLocation: false)

        try await waitForIdle(vm: vm)

        await MainActor.run {
            #expect(vm.chargingStations.count == 1)
            #expect(vm.chargingStations.first?.id == 401)
            #expect(persistence.savedStations.count == 1)
            #expect(persistence.savedStations.first?.id == 401)
        }
    }

    @Test("Generic fetch network failure -> uses cache when available")
    func testFetchChargingStations_noLocation_networkFailureUsesCache() async throws {
        let mockService = MockService()
        mockService.errorToThrow = URLError(.notConnectedToInternet)

        let mockLocation = MockLocationProvider()
        let cachedStation = makeSampleStation(id: 402, title: "Cached Generic Station")
        let persistence = MockPersistence()
        // pre-populate the cached result returned by fetchStations()
        persistence.fetchedStations = [cachedStation]

        let vm = await MainActor.run {
            ChargingStationsViewModel(service: mockService, locationProvider: mockLocation, persistence: persistence)
        }

        await vm.fetchChargingStations(useLocation: false)

        try await waitForIdle(vm: vm)

        await MainActor.run {
            #expect(vm.chargingStations.count == 1)
            #expect(vm.chargingStations.first?.id == 402)
            #expect(vm.isOffline == true)
        }
    }

    @Test("Generic fetch network failure + no cache -> error shown")
    func testFetchChargingStations_noLocation_networkFailureNoCacheShowsError() async throws {
        let mockService = MockService()
        mockService.errorToThrow = URLError(.notConnectedToInternet)

        let mockLocation = MockLocationProvider()
        let persistence = MockPersistence() // empty

        let vm = await MainActor.run {
            ChargingStationsViewModel(service: mockService, locationProvider: mockLocation, persistence: persistence)
        }

        await vm.fetchChargingStations(useLocation: false)

        try await waitForIdle(vm: vm)

        await MainActor.run {
            #expect(vm.chargingStations.isEmpty)
            #expect((vm.errorMessage ?? "").isEmpty == false)
        }
    }
}
