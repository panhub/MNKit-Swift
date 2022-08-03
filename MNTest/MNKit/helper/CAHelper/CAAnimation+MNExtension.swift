//
//  CAAnimation+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/8.
//

import QuartzCore
import Foundation

public extension CAAnimation {
    /**动画Key*/
    struct KeyPath {
        /* 形变*/
        static let transform: String = "transform"

        /* 旋转x,y,z分别是绕x,y,z轴旋转 */
        static let rotation: String = "transform.rotation"
        static let rotationX: String = "transform.rotation.x"
        static let rotationY: String = "transform.rotation.y"
        static let rotationZ: String = "transform.rotation.z"

        /* 缩放x,y,z分别是对x,y,z方向进行缩放 */
        static let scale: String = "transform.scale"
        static let scaleX: String = "transform.scale.x"
        static let scaleY: String = "transform.scale.y"
        static let scaleZ: String = "transform.scale.z"

        /* 平移x,y,z同上 */
        static let translation: String = "transform.translation"
        static let translationX: String = "transform.translation.x"
        static let translationY: String = "transform.translation.y"
        static let translationZ: String = "transform.translation.z"

        /* 平面 */
        /* CGPoint中心点改变位置，针对平面 */
        static let position: String = "position"
        static let positionX: String = "position.x"
        static let positionY: String = "position.y"

        /* CGRect */
        static let bounds: String = "bounds"
        static let boundsSize: String = "bounds.size"
        static let boundsSizeWidth: String = "bounds.size.width"
        static let boundsSizeHeight: String = "bounds.size.height"
        static let boundsOriginX: String = "bounds.origin.x"
        static let boundsOriginY: String = "bounds.origin.y"

        /* 透明度 */
        static let opacity: String = "opacity"
        /* 内容 */
        static let contents: String = "contents"
        /* 开始路径 */
        static let strokeStart: String = "strokeStart"
        /* 结束路径 */
        static let strokeEnd: String = "strokeEnd"
        /* 背景色 */
        static let backgroundColor: String = "backgroundColor"
        /* 圆角 */
        static let cornerRadius: String = "cornerRadius"
        /* 边框 */
        static let borderWidth: String = "borderWidth"
        /* 阴影颜色 */
        static let shadowColor: String = "shadowColor"
        /* 偏移量CGSize */
        static let shadowOffset: String = "shadowOffset"
        /* 阴影透明度 */
        static let shadowOpacity: String = "shadowOpacity"
        /* 阴影圆角 */
        static let shadowRadius: String = "shadowRadius"
    }
    
    static func basic(keyPath: String, duration: TimeInterval, from: Any? = nil, to: Any? = nil) ->CABasicAnimation  {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        animation.fromValue = from
        animation.toValue = to
        animation.autoreverses = false
        animation.beginTime = 0.0
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        return animation
    }
    
    static func rotation(to: Double, duration: TimeInterval) ->CABasicAnimation {
        let animation = basic(keyPath: CAAnimation.KeyPath.rotationZ, duration: duration, to: to)
        animation.repeatCount = Float.greatestFiniteMagnitude
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        return animation
    }
    
    static func contents(to: Any, duration: TimeInterval) -> CABasicAnimation {
        return basic(keyPath: CAAnimation.KeyPath.contents, duration: duration, to: to)
    }
    
    static func keyframe(keyPath: String, duration: TimeInterval, values: [Any]?, times: [NSNumber]?) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.autoreverses = false
        animation.beginTime = 0.0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.values = values
        animation.keyTimes = times
        return animation
    }
}
