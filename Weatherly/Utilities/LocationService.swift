//
//  LocationService.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 21/11/2026.
//

import CoreLocation

/// Manages authorization for device location and publishes location updates.
///
/// The service requests When In Use authorization when it is created. It starts
/// receiving updates after authorization and stops when access is denied or
/// restricted. Subscribe to ``locationSequence()`` to receive the latest location
/// state and subsequent changes.
@MainActor
final class LocationService: NSObject {
    
    // MARK: - Properties
    
    /// The most recently published location, or `nil` when no location is available.
    ///
    /// Temporary location errors preserve the last successful location. The service
    /// clears this property when Core Location reports denied or restricted access.
    private(set) var location: CLLocation?

    /// Broadcasts location changes to independent asynchronous consumers.
    private let locationStream = AsyncStreamHub<CLLocation?>()

    /// Provides authorization and location updates from Core Location.
    private let locationManager = CLLocationManager()

    /// Indicates whether this service has started continuous location updates.
    private var isUpdatingLocation = false
    
    // MARK: - Init
    
    /// Creates the location manager, assigns its delegate, and requests authorization if needed.
    ///
    /// If authorization is already granted, location updates start immediately. If
    /// access is denied or restricted, the service publishes `nil` as its location.
    override init() {
        super.init()
        locationManager.delegate = self

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted:
            handle(status: locationManager.authorizationStatus)
        @unknown default:
            handle(status: locationManager.authorizationStatus)
        }
    }

    // MARK: - Methods
    
    /// Creates a stream for one consumer and replays the latest published location state.
    ///
    /// The stream emits `nil` when access is denied or restricted. Temporary errors
    /// don't emit a new value, leaving the last successful location available.
    func locationSequence() -> AsyncStream<CLLocation?> {
        locationStream.makeStream(replayLatest: true)
    }

    /// Starts or stops location updates to match Core Location's authorization state.
    ///
    /// Undetermined authorization is left unchanged because the initializer already
    /// requested permission. Denied or restricted authorization stops updates and
    /// clears the last published location.
    ///
    /// - Parameter status: The current authorization status reported by Core Location.
    private func handle(status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            beginLocationUpdates()
        case .denied, .restricted:
            endLocationUpdates()
            updateLocation(nil)
        case .notDetermined:
            break
        @unknown default:
            endLocationUpdates()
            updateLocation(nil)
        }
    }

    /// Starts continuous updates once, after authorization has been granted.
    private func beginLocationUpdates() {
        guard !isUpdatingLocation else { return }
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }

    /// Stops continuous updates if they are currently active.
    private func endLocationUpdates() {
        guard isUpdatingLocation else { return }
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    /// Stores a location and broadcasts it to all active consumers.
    ///
    /// Passing `nil` clears the current location and publishes that absence.
    ///
    /// - Parameter newLocation: The latest location, or `nil` when it should be cleared.
    private func updateLocation(_ newLocation: CLLocation?) {
        location = newLocation
        locationStream.yield(newLocation)
    }
}

// MARK: - Delegate

extension LocationService: CLLocationManagerDelegate {
    /// Applies authorization changes reported by Core Location.
    ///
    /// The callback is nonisolated, so it captures the status and applies it on the
    /// main actor, where the location manager and stream state are managed.
    ///
    /// - Parameter manager: The location manager reporting the authorization change.
    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let status = manager.authorizationStatus
        
        Task { @MainActor [weak self] in
            self?.handle(status: status)
        }
    }
    
    /// Publishes the newest location in a batch of updates.
    ///
    /// - Parameters:
    ///   - manager: The location manager reporting the update.
    ///   - locations: The locations received in this delegate callback.
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let newLocation = locations.last else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self, isUpdatingLocation else { return }
            updateLocation(newLocation)
        }
    }

    /// Clears the last location when Core Location reports denied access.
    ///
    /// Other errors leave the last successful location available.
    ///
    /// - Parameters:
    ///   - manager: The location manager reporting the failure.
    ///   - error: The error reported by Core Location.
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: any Error
    ) {
        let isDenied = (error as? CLError)?.code == .denied

        Task { @MainActor [weak self] in
            guard let self, isDenied, isUpdatingLocation else { return }
            updateLocation(nil)
            endLocationUpdates()
        }
    }
}
