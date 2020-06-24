//
//  MKCoordinateRegion+Earth.swift
//  Earth
//
//  Created by Simon Manning on 5/29/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import Foundation
import MapKit

extension MKCoordinateRegion {

    private typealias Transform = (CLLocationCoordinate2D) -> (CLLocationCoordinate2D)

    /// Create an `MKCoordinateRegion` from a set of coordinates.
    /// - Parameter coordinates: Set of coordinates to build region from.
    init?(coordinates: [CLLocationCoordinate2D]) {

        // Region centered around prime meridian
        let primeRegion = MKCoordinateRegion.region(
            for: coordinates,
            transform: { $0 },
            inverseTransform: { $0 }
        )

        // Region centered around 180th meridian
        let transformedRegion = MKCoordinateRegion.region(
            for: coordinates,
            transform: MKCoordinateRegion.transform,
            inverseTransform: MKCoordinateRegion.inverseTransform
        )

        // Find smallest longitude delta
        if let a = primeRegion,
            let b = transformedRegion,
            let min = [a, b].min(by: { $0.span.longitudeDelta < $1.span.longitudeDelta }) {
            self = min
        } else if let a = primeRegion {
            self = a
        } else if let b = transformedRegion {
            self = b
        } else {
            return nil
        }
    }

    // -180 ... 180 -> 0 ... 360
    private static func transform(_ c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        if c.longitude < 0 { return CLLocationCoordinate2DMake(c.latitude, 360 + c.longitude) }
        return c
    }

    // 0 ... 360 -> -180 ... 180
    private static func inverseTransform(_ c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        if c.longitude > 180 { return CLLocationCoordinate2DMake(c.latitude, -360 + c.longitude) }
        return c
    }

    private static func region(for coordinates: [CLLocationCoordinate2D], transform: Transform, inverseTransform: Transform) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else {
            return nil
        }

        guard coordinates.count > 1 else {
            return MKCoordinateRegion(center: coordinates[0],
                                      span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        }

        let transformed = coordinates.map(transform)

        // Determine span
        guard let minLat = transformed.min(by: { $0.latitude < $1.latitude })?.latitude,
            let maxLat = transformed.max(by: { $0.latitude < $1.latitude })?.latitude,
            let minLon = transformed.min(by: { $0.longitude < $1.longitude })?.longitude,
            let maxLon = transformed.max(by: { $0.longitude < $1.longitude })?.longitude else {
                return nil
        }

        let span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)

        // Get the center of span
        let center = inverseTransform(CLLocationCoordinate2DMake((maxLat - span.latitudeDelta / 2),
                                                                 maxLon - span.longitudeDelta / 2))
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Bounding

extension MKCoordinateRegion {
    var northWest: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta / 2,
                                      longitude: center.longitude - span.longitudeDelta / 2)
    }
    var northEast: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta / 2,
                                      longitude: center.longitude + span.longitudeDelta / 2)
    }
    var southWest: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta / 2,
                                      longitude: center.longitude - span.longitudeDelta / 2)
    }
    var southEast: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta / 2,
                                      longitude: center.longitude + span.longitudeDelta / 2)
    }
}
