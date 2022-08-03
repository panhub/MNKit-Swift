//
//  Bool+MNExtension.swift
//  anhe
//
//  Created by 冯盼 on 2022/3/24.
//  

import Foundation
import CoreGraphics

extension Bool {
    var boolValue: Bool { self }
    // Bool => Double
    var doubleValue: Double { self ? 1.0 : 0.0 }
    // Bool => Int
    var intValue: Int { self ? 1 : 0 }
    // Bool => NSInteger
    var integerValue: NSInteger { self ? 1 : 0 }
    // Bool => CGFloat
    var floatValue: CGFloat { self ? 1.0 : 0.0 }
}
