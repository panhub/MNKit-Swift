//
//  UINavigationController+MNExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/14.
//  导航控制器扩展

import UIKit

extension UINavigationController {
    // 当前导航控制器
    @objc static var currentNav: UINavigationController? {
        guard let vc = UIViewController.current else { return nil }
        if vc is UINavigationController {
            return vc as? UINavigationController
        } else if let nav = vc.navigationController {
            return nav
        }
        return nil
    }
    
    // 寻找控制器
    func seek<T>(_ cls: T.Type) -> T? {
        for vc in viewControllers.reversed() {
            if vc is T {
                return vc as? T
            }
        }
        return nil
    }
}
