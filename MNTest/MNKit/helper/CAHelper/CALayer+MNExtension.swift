//
//  CALayer+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/17.
//

import UIKit
import Foundation
import QuartzCore

extension CALayer {
    
    /// 摇晃方向
    @objc enum ShakeOrientation: Int {
        case horizontal, vertical
    }
    
    /// 截图
    @objc var snapshot: UIImage? {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { context in
                render(in: context.cgContext)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, contentsScale)
            if let context = UIGraphicsGetCurrentContext() {
                render(in: context)
            }
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
    }
    
    /// 设置圆角效果
    /// - Parameters:
    ///   - radius: 圆角大小
    ///   - corners: 圆角位置
    @objc func mask(radius: CGFloat, corners: UIRectCorner) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.mask = mask
    }
    
    /// 摆动
    /// - Parameters:
    ///   - orientation: 方向
    ///   - duration: 时长
    ///   - extent: 摇摆的幅度
    ///   - completion: 结束回调
    @objc func swing(orientation: ShakeOrientation = .horizontal, duration: TimeInterval = 0.8, extent: CGFloat = 6.0, completion: (()->Void)? = nil) {
        let spring: CGFloat = abs(extent)
        let animation = CAKeyframeAnimation(keyPath: orientation == .horizontal ? "transform.translation.x" : "transform.translation.y")
        animation.duration = duration
        animation.autoreverses = false
        animation.isRemovedOnCompletion = true
        //animation.repeatCount = Float.greatestFiniteMagnitude
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.values = [-spring/2.0, 0.0, spring/2.0, 0.0, -spring/2.0, -spring, -spring/2.0, 0.0, spring/2.0, spring, spring/3.0*2.0, spring/3.0, 0.0, -spring/3.0, -spring/3.0*2.0, -spring/3.0, 0.0, spring/3.0, spring/3.0*2.0, spring/3.0, 0.0, -spring/3.0, 0.0, spring/3.0, 0.0]
        removeAnimation(forKey: "com.mn.swing.animation")
        add(animation, forKey: "com.mn.swing.animation")
        guard let completion = completion else { return }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration + 0.1, execute: completion)
    }
    
    /// 摇动
    /// - Parameters:
    ///   - radian: 摇动弧度
    ///   - duration: 时长
    ///   - completion: 结束回调
    @objc func shake(radian: Double = 5.0/180.0*Double.pi, duration: TimeInterval = 0.35, completion: (()->Void)? = nil) {
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
        animation.duration = duration
        animation.repeatCount = Float.greatestFiniteMagnitude
        animation.values = [-abs(radian), 0.0, abs(radian), 0.0]
        animation.autoreverses = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        removeAnimation(forKey: "com.mn.shake.animation")
        add(animation, forKey: "com.mn.shake.animation")
        guard let completion = completion else { return }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration + 0.1, execute: completion)
    }
}

extension CALayerContentsGravity {
    
    /// CALayerContentsGravity => UIView.ContentMode
    var mode: UIView.ContentMode {
        switch self {
        case .center: return .center
        case .top: return .top
        case .bottom: return .bottom
        case .left: return .left
        case .right: return .right
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        case .resize: return .scaleToFill
        case .resizeAspect: return .scaleAspectFit
        case .resizeAspectFill: return .scaleAspectFill
        default: return .scaleToFill
        }
    }
}
 
