//
//  TLTabBarController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  标签栏控制

import UIKit

class TLTabBarController: MNTabBarController {
    
    /// 提供快速获取标签控制器入口
    static var shared: TLTabBarController! {
        UIWindow.current?.rootViewController as? TLTabBarController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tabbar?.translucent = false
        tabbar?.backgroundColor = .white
    }
    
    override func shouldMove(viewController vc: UIViewController, to index: Int) -> UIViewController? {
        TLNavigationController(rootViewController: vc)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
