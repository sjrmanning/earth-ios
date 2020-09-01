//
//  MapDrawingView.swift
//  Earth
//
//  Created by Simon Manning on 6/7/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import RxCocoa
import RxSwift

final class MapDrawingView: UIView {

    // MARK: - Properties

    private weak var mapView: MKMapView?

    let pixelEvent = PublishRelay<MapPixel>()
    let pixels = BehaviorRelay<[MapPixel]>(value: [])

    private var lastTouchPoint: Any?
    private let hashPixelPrecision: Int

    // MARK: - Init

    init(mapView: MKMapView, hashPixelPrecision: Int = Constants.hashPixelPrecision) {
        self.mapView = mapView
        self.hashPixelPrecision = hashPixelPrecision

        super.init(frame: .zero)

        backgroundColor = .clear
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 1.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let hash = hashFromTouch(touches.first), let region = regionFromHash(hash) else {
            return
        }

        pushNewPixel(MapPixel(geohash: hash, region: region, color: .black))
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let hash = hashFromTouch(touches.first),
                  pixels.value.last?.geohash != hash,
                  let region = regionFromHash(hash) else {
            return
        }

        pushNewPixel(MapPixel(geohash: hash, region: region, color: .black))
        setNeedsDisplay()
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            return
        }

        for pixel in pixels.value {
            if let rect = mapView?.convert(pixel.region, toRectTo: self) {
                context.addRect(rect)
                context.fill(rect)
            }
        }
    }

    // MARK: - Private

    /// Accepts a new individual pixel, updating accumulated pixels and publishing to single pixel relay.
    /// - Parameter pixel: New pixel to accept.
    private func pushNewPixel(_ pixel: MapPixel) {
        pixelEvent.accept(pixel)
        pixels.accept(pixels.value + [pixel])
    }

    private func hashFromTouch(_ touch: UITouch?) -> String? {
        guard let touch = touch else {
            return nil
        }

        let mapPoint = touch.location(in: self)
        guard let coordinate = mapView?.convert(mapPoint, toCoordinateFrom: self) else {
            return nil
        }

        return Geohash.encode(latitude: coordinate.latitude, longitude: coordinate.longitude, hashPixelPrecision)
    }

    private func regionFromHash(_ hash: String) -> MKCoordinateRegion? {
        guard let box = Geohash.geohashbox(hash) else {
            return nil
        }

        return MKCoordinateRegion(coordinates: [box.northWest, box.southEast])
    }
}

// MARK: - Reactive extensions

extension Reactive where Base: MapDrawingView {
    /// Stream of active total pixels.
    var accumulatedPixels: Driver<[MapPixel]> {
        base.pixels.asDriver()
    }

    /// Stream of pixels as they come through.
    var singlePixels: Driver<MapPixel> {
        base.pixelEvent.asDriver(onErrorDriveWith: .never())
    }
}
