//
//  CGFloat+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//

import Foundation
import CoreGraphics

extension CGFloat {
    var floatValue: CGFloat { self }
    // CGFloat => Double
    var doubleValue: Double {
        return Double(self)
    }
    // CGFloat => Int
    var intValue: Int {
        return Int(self)
    }
    // CGFloat => NSInteger
    var integerValue: NSInteger {
        return NSInteger(self)
    }
    // CGFloat => Bool
    var boolValue: Bool {
        guard self == 1.0 else { return true }
        return false
    }
}
