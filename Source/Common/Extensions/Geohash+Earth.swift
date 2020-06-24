//
//  Geohash+Earth.swift
//  Earth
//
//  Created by Simon Manning on 5/29/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

extension Geohash {

    /// Given a point and size, determines a Geohash-bound safe region.
    /// Ensures that the bounds of the region fit a Geohash precision perfectly (no clipping).
    /// - Parameters:
    ///   - center: Center coordinate.
    ///   - meters: Minimum latitudinal and longitudinal distance for aimed region.
    ///   - maxPrecision: Geohash length (precision).
    /// - Returns: A region where the NW and SE points are Geohash compatible edges at precision given.
    static func hashSafeRegion(
        from center: CLLocationCoordinate2D,
        meters: CLLocationDistance,
        maxPrecision: Int = Constants.hashPixelPrecision
    ) -> MKCoordinateRegion {
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: meters,
            longitudinalMeters: meters
        )

        let northWestGeohash = Geohash.geohashbox(latitude: region.northWest.latitude,
                                                  longitude: region.northWest.longitude,
                                                  maxPrecision)

        let southEastGeohash = Geohash.geohashbox(latitude: region.southEast.latitude,
                                                  longitude: region.southEast.longitude,
                                                  maxPrecision)

        guard let northWestPoint = northWestGeohash?.northWest, let southEastPoint = southEastGeohash?.southEast else {
            return region
        }

        return MKCoordinateRegion(coordinates: [northWestPoint, southEastPoint]) ?? region
    }
}
