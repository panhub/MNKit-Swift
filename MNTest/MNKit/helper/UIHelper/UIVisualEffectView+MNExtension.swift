//
//  UIVisualEffectView+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//  毛玻璃视图

import UIKit
import Foundation

public extension UIVisualEffectView {
    class func blurEffect(frame rect: CGRect, style: UIBlurEffect.Style) -> UIVisualEffectView {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        effectView.frame = rect
        return effectView
    }
}
