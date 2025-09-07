//
//  LocationManager.swift
//  EVChargingStations
//
//  Created by Harshith Bhupal Vakeel on 9/7/25.
//

import Foundation
import CoreLocation

// MARK: - LocationProvider

public protocol LocationProvider {
    func currentLocation() async throws -> CLLocationCoordinate2D
}

// MARK: - LocationManager

public final class LocationManager: NSObject, LocationProvider {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var didRequestLocation: Bool = false
    private let requestTimeout: TimeInterval = 10
    private let stateQueue = DispatchQueue(label: "EVChargingStations.LocationManager.stateQueue")

    public init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.delegate = self
    }

    deinit {
        // If a continuation is still pending at deinit, complete it with an error.
        completeContinuationIfPresent(with: .failure(LocationError.unableToDetermineLocation))
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    public func currentLocation() async throws -> CLLocationCoordinate2D {
        // Prevent overlapping requests.
        if stateQueue.sync(execute: { continuation != nil }) {
            throw LocationError.requestAlreadyInProgress
        }

        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            throw LocationError.authorizationDenied
        }

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocationCoordinate2D, Error>) in
            stateQueue.sync {
                self.continuation = cont
                self.didRequestLocation = false
            }

            let statusNow = manager.authorizationStatus
            if statusNow == .authorizedWhenInUse || statusNow == .authorizedAlways {
                startRequestingLocation()
            }
        }
    }

    private func startRequestingLocation() {
        // Ensure only a single request is started.
        var shouldStart = false
        stateQueue.sync {
            shouldStart = (continuation != nil) && !didRequestLocation
            if shouldStart { didRequestLocation = true }
        }
        guard shouldStart else { return }

        manager.requestLocation()

        timeoutTask?.cancel()
        // Use detached task to avoid inheriting caller context.
        timeoutTask = Task.detached { [weak self] in
            let timeoutNanos = UInt64((self?.requestTimeout ?? 10) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: timeoutNanos)
            guard let self = self else { return }
            self.completeContinuationIfPresent(with: .failure(LocationError.timeout))
        }
    }

    private func completeContinuationIfPresent(with result: Result<CLLocationCoordinate2D, Error>) {
        var cont: CheckedContinuation<CLLocationCoordinate2D, Error>?
        stateQueue.sync {
            cont = self.continuation
            self.continuation = nil
            self.didRequestLocation = false
            self.timeoutTask?.cancel()
            self.timeoutTask = nil
        }
        guard let continuation = cont else { return }
        switch result {
        case .success(let coordinate):
            continuation.resume(returning: coordinate)
        case .failure(let err):
            continuation.resume(throwing: err)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else {
            completeContinuationIfPresent(with: .failure(LocationError.unableToDetermineLocation))
            return
        }
        completeContinuationIfPresent(with: .success(loc.coordinate))
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completeContinuationIfPresent(with: .failure(error))
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            completeContinuationIfPresent(with: .failure(LocationError.authorizationDenied))
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Start request if one is awaiting authorization.
            var shouldStart = false
            stateQueue.sync {
                shouldStart = (continuation != nil) && !didRequestLocation
                if shouldStart { didRequestLocation = true }
            }
            if shouldStart {
                manager.requestLocation()
                timeoutTask?.cancel()
                timeoutTask = Task.detached { [weak self] in
                    let timeoutNanos = UInt64((self?.requestTimeout ?? 10) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: timeoutNanos)
                    guard let self = self else { return }
                    self.completeContinuationIfPresent(with: .failure(LocationError.timeout))
                }
            }
        }
    }
}

// MARK: - Location Errors

public enum LocationError: Error, LocalizedError {
    case authorizationDenied
    case unableToDetermineLocation
    case requestAlreadyInProgress
    case timeout

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied: return "Location permission denied."
        case .unableToDetermineLocation: return "Unable to determine location."
        case .requestAlreadyInProgress: return "A location request is already in progress."
        case .timeout: return "Timed out waiting for location."
        }
    }
}
