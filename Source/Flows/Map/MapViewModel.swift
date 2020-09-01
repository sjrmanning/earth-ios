//
//  MapViewModel.swift
//  Earth
//
//  Created by Simon Manning on 5/24/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MapKit

final class MapViewModel: ViewModel {

    // MARK: - Modes

    enum Mode {
        case explore
        case draw
    }

    // MARK: - Properties

    let state = BehaviorRelay<State>(value: .exploring)
    let visiblePixels = BehaviorRelay<[MapPixel]>(value: [])

    private let disposeBag = DisposeBag()
}

// MARK: - State Machine

extension MapViewModel {
    enum State {
        case exploring
        case drawing(area: MKCoordinateRegion)
    }

    enum Event {
        case changedMode(Mode, region: MKCoordinateRegion)
        case drew(pixel: MapPixel)
        case regionChanged(region: MKCoordinateRegion)
    }

    func reduce(_ state: State, _ event: Event) -> State {
        switch (state, event) {

        case let (state, .regionChanged(_)):
            // TODO: Determine visible pixels specific to this region.
            // Eventually ping socket to get updates, but for now we don't have any pixels to add.
            return state

        case let (.drawing(area), .drew(pixel)):
            // TODO: Send these locations/geohashes through to backend for live drawing and persistence.
            visiblePixels.accept(visiblePixels.value + [pixel])
            return .drawing(area: area)

        case let (_, .changedMode(mode, region)):
            switch mode {
            case .draw:
                let drawRegion = Geohash.hashSafeRegion(from: region.center, meters: 200)
                return .drawing(area: drawRegion)
            case .explore:
                return .exploring
            }

            case (.exploring, _):
                return .exploring
        }
    }

    static private func drawableRegion(from region: MKCoordinateRegion) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: region.center,
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
    }
}
