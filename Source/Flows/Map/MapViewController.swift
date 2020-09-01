//
//  MapViewController.swift
//  Earth
//
//  Created by Simon Manning on 5/25/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import Foundation
import UIKit

import MapKit
import RxSwift
import RxCocoa
import Cartography
import RxGesture
import RxOptional
import GoogleMapsTileOverlay

final class MapViewController: BaseViewController<MapViewModel> {

    // MARK: - Properties

    private lazy var styleOverlay: GoogleMapsTileOverlay? = {
        guard let jsonURL = Bundle.main.url(forResource: "MapStyle", withExtension: "json"),
            let tileOverlay = try? GoogleMapsTileOverlay(jsonURL: jsonURL) else {
            return nil
        }

        tileOverlay.canReplaceMapContent = true
        return tileOverlay
    }()

    // MARK: - Subviews

    private lazy var mapView: MKMapView = {
        let view = MKMapView()
        view.delegate = self
        view.pointOfInterestFilter = .excludingAll
        return view
    }()

    private lazy var modeView: UISegmentedControl = {
        return UISegmentedControl(items: ["Explore", "Draw"])
    }()

    private lazy var drawView: MapDrawingView = {
        MapDrawingView(mapView: mapView)
    }()

    private lazy var readOnlyView: MapDrawingView = {
        let view = MapDrawingView(mapView: mapView)
        view.isUserInteractionEnabled = false
        return view
    }()

    // MARK: - Setup

    override func setupSubviews() {
        super.setupSubviews()

        view.backgroundColor = .white
        view.addSubview(mapView)
        view.addSubview(readOnlyView)
        view.addSubview(drawView)
        view.addSubview(modeView)

        // Start in "Explore" mode.
        modeView.selectedSegmentIndex = 0
        drawView.isHidden = true

        if let styleOverlay = styleOverlay {
            mapView.addOverlay(styleOverlay)
        }

        let defaultRegion = MKCoordinateRegion(
            center: .init(latitude: 40.732783, longitude: -73.989220),
            latitudinalMeters: 300,
            longitudinalMeters: 300
        )

        mapView.setRegion(defaultRegion, animated: false)
    }

    override func setupConstraints() {
        super.setupConstraints()

        constrain(view, mapView) { $1.edges == $0.edges }
        constrain(mapView, readOnlyView) { $1.edges == $0.edges }
        constrain(view, modeView) { view, mode in
            mode.left >= view.left + 32
            mode.right <= view.right - 32
            mode.centerX == view.centerX
            mode.top == view.safeAreaLayoutGuide.top + 16
        }
    }

    override func bindEvents() {
        super.bindEvents()

        // Push pixels from the VM to the read-only view for rendering.
        viewModel.visiblePixels.subscribe(onNext: { [weak readOnlyView] pixels in
            readOnlyView?.pixels.accept(pixels)
            readOnlyView?.setNeedsDisplay()
        }).disposed(by: disposeBag)

        // Mode change event
        let modes: [Int: MapViewModel.Mode] = [0: .explore, 1: .draw]
        modeView.rx.value
            .map { modes[$0] ?? .explore }
            .map { [weak self] newMode -> Event? in
                guard let self = self else { return nil }
                return .changedMode(newMode, region: self.mapView.region)
        }
        .filterNil()
        .bind(to: eventRelay)
        .disposed(by: disposeBag)

        // Capture each new pixel as drawn as an event.
        drawView.rx.singlePixels
            .map { .drew(pixel: $0) }
            .asObservable()
            .bind(to: eventRelay)
            .disposed(by: disposeBag)
    }

    override func updateState(_ state: BaseViewController<MapViewModel>.State) {
        switch state {
        case .exploring:
            drawView.isHidden = true
            mapView.isScrollEnabled = true

        case let .drawing(region):
            drawView.isHidden = false
            redisplayPixelViews(in: region)
            mapView.isScrollEnabled = false
        }
    }

    // MARK: - Private

    private func redisplayPixelViews(in region: MKCoordinateRegion) {
        drawView.frame = mapView.convert(region, toRectTo: view)
        drawView.setNeedsDisplay()
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        readOnlyView.setNeedsDisplay()

        guard case let .drawing(region) = viewModel.state.value else {
            return
        }

        redisplayPixelViews(in: region)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tileOverlay)
        }

        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = .black
            return renderer
        }

        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.fillColor = .black
            renderer.lineWidth = 1
            renderer.strokeColor = .black
            return renderer
        }

        return MKOverlayRenderer()
    }
}
