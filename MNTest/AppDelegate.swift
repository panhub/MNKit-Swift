//
//  AppDelegate.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/2.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        window.makeKeyAndVisible()
        window.rootViewController = MNNavigationController(rootViewController: FirstViewController())
        self.window = window
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyy-MM-dd HH:mm:ss"
        let date = formatter.date(from: "2022-9-19 00:00:00")
        formatter.dateFormat = "yyy-MM-dd hh:mm:ss"
        let s = formatter.string(from: date!)
        
        print(s)
        
        
        
        return true
    }
}

