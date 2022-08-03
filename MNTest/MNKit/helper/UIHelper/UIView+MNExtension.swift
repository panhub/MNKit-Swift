//
//  UIView+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//

import UIKit
import Foundation

public extension UIView {
    
    /*所在控制器**/
    @objc var viewController: UIViewController? {
        var responder = next
        while let res = responder {
            if res is UIViewController { return res as? UIViewController }
            responder = res.next
        }
        return nil
    }
    
    func responder<T: UIResponder>(cls: T.Type) -> T? {
        var responder = next
        while let res = responder {
            if res is T { return res as? T }
            responder = res.next
        }
        return nil
    }
    
    /*设置锚点但不改变相对位置**/
    @objc var anchorPoint: CGPoint {
        get { layer.anchorPoint }
        set {
            let x = min(max(0.0, newValue.x), 1.0)
            let y = min(max(0.0, newValue.y), 1.0)
            let frame = frame
            let point = layer.anchorPoint
            let xMargin = x - point.x
            let yMargin = y - point.y
            layer.anchorPoint = CGPoint(x: x, y: y)
            var position = layer.position
            position.x += xMargin*frame.size.width
            position.y += yMargin*frame.size.height
            layer.position = position
        }
    }
    
    /*移除所有子视图**/
    @objc func removeAllSubviews() {
        for view in subviews.reversed() {
            willRemoveSubview(view)
            view.willMove(toSuperview: nil)
            view.removeFromSuperview()
        }
    }
    
    /// 九宫格布局
    /// - Parameters:
    ///   - rect: 第一个视图位置
    ///   - offset: 视图偏移
    ///   - count: 数量
    ///   - column: 列数
    ///   - block: 创建视图回调
    @objc static func grid(rect: CGRect, offset: UIOffset, count: Int, column: Int, using block: (Int, CGRect,  UnsafeMutablePointer<Bool>)->Void) {
        rect.grid(offset: offset, count: count, column: column, using: block)
    }
    
    /// 以自身宽度约束尺寸
    @objc func sizeFitToWidth() {
        guard let image = background, image.size.width > 0.0 else { return }
        var frame = frame
        frame.size.height = ceil(image.size.height/image.size.width*frame.width)
        self.frame = frame
    }
    
    /// 以自身高度约束尺寸
    @objc func sizeFitToHeight() {
        guard let image = background, image.size.height > 0.0 else { return }
        var frame = frame
        frame.size.width = ceil(image.size.width/image.size.height*frame.height)
        self.frame = frame
    }
}

extension UIView.ContentMode {
    
    /// UIView.ContentMode => CALayerContentsGravity
    var gravity: CALayerContentsGravity {
        switch self {
        case .scaleToFill: return .resize
        case .scaleAspectFit: return .resizeAspect
        case .scaleAspectFill: return .resizeAspectFill
        case .top: return .top
        case .left: return .left
        case .bottom: return .bottom
        case .right: return .right
        case .center: return .center
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        default:  return .resize
        }
    }
}
