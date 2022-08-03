//
//  UIView+MNLayout.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//  视图位置便捷方法

import UIKit
import CoreGraphics

public extension UIView {
    /// 原点
    @objc var origin: CGPoint {
        get { frame.origin }
        set {
            var frame = self.frame
            frame.origin = newValue
            self.frame = frame
        }
    }
    /// 大小
    @objc var size: CGSize {
        get { frame.size }
        set {
            var frame = self.frame
            frame.size = newValue
            self.frame = frame
        }
    }
    /// 左
    @objc var minX: CGFloat {
        get { frame.minX }
        set {
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }
    /// 右
    @objc var maxX: CGFloat {
        get { frame.maxX }
        set {
            var frame = self.frame
            frame.origin.x = newValue - frame.size.width
            self.frame = frame
        }
    }
    /// 上
    @objc var minY: CGFloat {
        get { frame.minY }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
    /// 下
    @objc var maxY: CGFloat {
        get { frame.maxY }
        set {
            var frame = self.frame
            frame.origin.y = newValue - frame.size.height
            self.frame = frame
        }
    }
    /// 宽
    @objc var width: CGFloat {
        get { frame.width }
        set {
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }
    /// 高
    @objc var height: CGFloat {
        get { frame.height }
        set {
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    /// 横向中心
    @objc var midX: CGFloat {
        get { center.x }
        set {
            var center = self.center
            center.x = newValue
            self.center = center
        }
    }
    /// 纵向中心
    @objc var midY: CGFloat {
        get { center.y }
        set {
            var center = self.center
            center.y = newValue
            self.center = center
        }
    }
    ///  自身中心点
    @objc var Center: CGPoint {
        return CGPoint(x: bounds.minX + bounds.midX, y: bounds.minY + bounds.midY)
    }
}
