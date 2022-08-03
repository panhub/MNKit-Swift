//
//  UIBezierPath+MNExtension.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/5.
//

import UIKit
import Foundation

extension UIBezierPath {
    
    /// 边框贝塞尔曲线
    /// - Parameters:
    ///   - rect: 边框
    ///   - edges: 线条矩阵
    convenience init(roundedRect rect: CGRect, edges: UIRectEdge) {
        self.init()
        if edges.contains(.top) {
            move(to: CGPoint(x: rect.maxX, y: rect.minY))
            addLine(to: rect.origin)
        }
        if edges.contains(.left) {
            move(to: rect.origin)
            addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        if edges.contains(.bottom) {
            move(to: CGPoint(x: rect.minX, y: rect.maxY))
            addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        if edges.contains(.right) {
            move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}
