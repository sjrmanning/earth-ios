//
//  AppDelegate.swift
//  Earth
//
//  Created by Simon Manning on 5/24/20.
//  Copyright © 2020 Earth. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties

    var window: UIWindow?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        window?.rootViewController = MapViewController(viewModel: MapViewModel())
        window?.makeKeyAndVisible()

        return true
    }
}

