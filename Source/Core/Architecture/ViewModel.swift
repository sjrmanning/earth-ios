//
//  ViewModel.swift
//  Earth
//
//  Created by Simon Manning on 5/25/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

protocol ViewModel: AnyObject {
    associatedtype State
    associatedtype Event

    /// Published State.
    var state: BehaviorRelay<State> { get }

    /// State machine reduction.
    func reduce(_ state: State, _ event: Event) -> State
}

extension ViewModel {

    /// Binds view events to the ViewModel, automatically recalculating and updating state.
    /// - Parameter events: Stream of applicable view events.
    /// - Returns: A `Disposable` object to add to a `DisposeBag`.
    func bindEvents(_ events: PublishRelay<Event>) -> Disposable {
        events
            .withLatestFrom(state) { ($1, $0) }
            .map { [weak self] in self?.reduce($0, $1) }
            .filterNil()
            .bind(to: state)
    }
}
