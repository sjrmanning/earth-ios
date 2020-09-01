//
//  MapPixel.swift
//  Earth
//
//  Created by Simon Manning on 6/26/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import Foundation
import UIKit
import MapKit

/// Represents a drawn pixel on top of the map.
struct MapPixel {
    /// Geohash location of pixel.
    let geohash: String

    /// MapKit equivalent coordinate region.
    let region: MKCoordinateRegion

    /// Pixel color.
    let color: UIColor
}
