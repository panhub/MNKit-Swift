//
//  UIWindow+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/6.
//

import UIKit
import Foundation

public extension UIWindow {
    @objc static var current: UIWindow? {
        if #available(iOS 15.0, *) {
            return current(in: UIApplication.shared.delegate?.window??.windowScene?.windows.reversed())
        } else {
            return current(in: UIApplication.shared.windows.reversed())
        }
    }
    
    private static func current(in windows: [UIWindow]?) -> UIWindow? {
        guard let windows = windows else { return nil }
        for window in windows {
            let isOnMainScreen = window.screen == UIScreen.main
            let isVisible = (window.isHidden == false && window.alpha > 0.01)
            if isOnMainScreen, isVisible, window.isKeyWindow {
                return window
            }
        }
        return nil
    }
}
