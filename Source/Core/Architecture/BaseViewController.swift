//
//  BaseViewController.swift
//  Earth
//
//  Created by Simon Manning on 5/25/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa

class BaseViewController<VM>: UIViewController where VM: ViewModel {

    // MARK: - Types

    typealias State = VM.State
    typealias Event = VM.Event

    // MARK: - Properties

    let viewModel: VM

    let eventRelay = PublishRelay<Event>()

    let disposeBag = DisposeBag()

    // MARK: - Init

    init(viewModel: VM) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View events

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
        setupConstraints()
        bindEvents()
    }

    func setupSubviews() {

    }

    func setupConstraints() {

    }

    func bindEvents() {
        viewModel.bindEvents(eventRelay)
            .disposed(by: disposeBag)
        viewModel.state.subscribe(onNext: { [weak self] in self?.updateState($0) })
            .disposed(by: disposeBag)
    }


    // MARK: - State Display

    func updateState(_ state: State) {

    }
}
