//
//  ChargingStationsViewModel.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import CoreLocation
import Foundation
import SwiftUI

@MainActor
public final class ChargingStationsViewModel: ObservableObject {
    // MARK: - Published properties
    @Published public private(set) var chargingStations: [ChargingStation] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var isOffline: Bool = false
    @Published public private(set) var showRetryWithoutLocation: Bool = false
    @Published public var selectedStation: ChargingStation?

    // MARK: - Dependencies
    private let service: OpenChargeMapServiceProtocol
    private let locationProvider: LocationProvider
    private let persistence: PersistenceProtocol

    // MARK: - Config
    public var defaultDistanceKm: Double = 20
    public var defaultMaxResults: Int = 100
    private var currentLoadTask: Task<Void, Never>?

    // MARK: - Init
    public init(
        service: OpenChargeMapServiceProtocol,
        locationProvider: LocationProvider,
        persistence: PersistenceProtocol
    ) {
        self.service = service
        self.locationProvider = locationProvider
        self.persistence = persistence
    }

    // MARK: - Public API

    /// Fetch charging stations. If `useLocation` is true, attempt a location-centered search first.
    /// If `useLocation` is false, uses the generic (no-location) endpoint.
    public func fetchChargingStations(useLocation: Bool) {
        currentLoadTask?.cancel()

        currentLoadTask = Task { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            self.errorMessage = nil
            self.isOffline = false
            self.showRetryWithoutLocation = false

            // If offline, try cache first and return an appropriate message if empty.
            if !NetworkMonitor.shared.isConnected {
                let cached = self.persistence.fetchStations()
                if !cached.isEmpty {
                    self.chargingStations = cached
                    self.isOffline = true
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "No internet connection and no cached data available."
                }
                self.isLoading = false
                self.currentLoadTask = nil
                return
            }

            // Online → attempt fetch (location preferred if requested)
            await self.performOnlineFetch(useLocation: useLocation, distance: defaultDistanceKm, results: defaultMaxResults)

            // If caller asked for location and we returned 0 results, expose retry-without-location option
            if useLocation && self.chargingStations.isEmpty && self.errorMessage == nil {
                // If we got empty result set (no stations found nearby)
                self.errorMessage = "No stations found nearby."
                self.showRetryWithoutLocation = true
            }

            self.isLoading = false
            self.currentLoadTask = nil
        }
    }

    /// Retry fetching but explicitly without using location (calls generic endpoint).
    public func retryWithoutLocation() {
        errorMessage = nil
        showRetryWithoutLocation = false
        fetchChargingStations(useLocation: false)
    }

    // MARK: - Private helpers

    /// Attempt to fetch stations when online. If useLocation==true, tries to obtain device location and
    /// performs a location-based fetch; if location fails we'll try generic fetch.
    private func performOnlineFetch(useLocation: Bool, distance: Double, results: Int) async {
        if useLocation {
            do {
                let coordinate = try await locationProvider.currentLocation()
                await getChargingStations(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    distance: distance,
                    results: results
                )
                // success path handled inside getChargingStations
                return
            } catch {
                // If location fetch fails, fall-through to generic fetch
                await getChargingStations(
                    latitude: nil,
                    longitude: nil,
                    distance: distance,
                    results: results
                )
                return
            }
        } else {
            await getChargingStations(latitude: nil, longitude: nil, distance: distance, results: results)
        }
    }

    private func getChargingStations(
        latitude: Double?,
        longitude: Double?,
        distance: Double,
        results: Int
    ) async {
        do {
            let fetched = try await service.fetchStations(
                latitude: latitude,
                longitude: longitude,
                distanceKm: distance,
                maxResults: results
            )
            chargingStations = fetched
            persistence.saveStations(fetched)
            isOffline = false
            errorMessage = nil
            showRetryWithoutLocation = false
        } catch {
            fallbackToCacheOrError(error)
        }
    }

    /// If network fetch fails, attempt to display cached data if present; otherwise show the error.
    private func fallbackToCacheOrError(_ error: Error) {
        let cached = persistence.fetchStations()
        if !cached.isEmpty {
            chargingStations = cached
            isOffline = true
            errorMessage = nil
            showRetryWithoutLocation = false
        } else {
            errorMessage = error.localizedDescription
            showRetryWithoutLocation = false
        }
    }

    // MARK: - Selection / cancellation
    public func selectStation(_ station: ChargingStation?) {
        selectedStation = station
    }

    public func cancelLoading() {
        currentLoadTask?.cancel()
        currentLoadTask = nil
        Task { @MainActor in self.isLoading = false }
    }

    // MARK: - Helpers
    public func station(withID id: Int) -> ChargingStation? {
        chargingStations.first { $0.id == id }
    }
}
