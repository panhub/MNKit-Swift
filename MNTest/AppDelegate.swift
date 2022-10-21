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
        
        return true
    }
    
    
    func shuffleArray(arr:[Int]) -> [Int] {
        var data:[Int] = arr
        for i in 1..<arr.count {
            let index:Int = Int(arc4random()) % i
            print(index)
            if index != i {
                data.swapAt(i, index)
            }
        }
        return data
    }
}

