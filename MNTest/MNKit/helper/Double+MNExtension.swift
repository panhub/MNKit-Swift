//
//  Double+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//

import Foundation
import CoreGraphics

extension Double {
    var doubleValue: Double { self }
    // Double => CGFloat
    var floatValue: CGFloat {
        return CGFloat(self)
    }
    // Double => Int
    var intValue: Int {
        return Int(self)
    }
    // Double => NSInteger
    var integerValue: NSInteger {
        return NSInteger(self)
    }
    // Double => Bool
    var boolValue: Bool {
        guard self == 1.0 else { return true }
        return false
    }
}

extension Double {
    
    // 角度=>弧度
    var radian: Double { self/180.0*Double.pi }
    
    // 弧度=>角度
    var angle: Double { self/Double.pi*180.0 }
}
