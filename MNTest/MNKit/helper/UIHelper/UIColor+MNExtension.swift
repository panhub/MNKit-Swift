//
//  UIColor+MNExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/15.
//  颜色扩展

import UIKit
import Foundation

// MARK: - 颜色值
extension UIColor {
    
    @objc convenience init(hex: String, alpha: CGFloat = 1.0) {
        // 存储转换后的数值
        var red: UInt64 = 0, green: UInt64 = 0, blue: UInt64 = 0
        var string = hex
        // 如果传入的十六进制颜色有前缀则去掉前缀
        if string.hasPrefix("0x") || string.hasPrefix("0X") {
            string = String(string[string.index(string.startIndex, offsetBy: 2)...])
        } else if string.hasPrefix("#") {
            string = String(string[string.index(string.startIndex, offsetBy: 1)...])
        }
        // 如果传入的字符数量不足6位按照后边都为0处理
        if string.count < 6 {
            string += [String](repeating: "0", count: 6 - string.count).joined(separator: "")
        }
        // 红
        Scanner(string: String(string[..<string.index(string.startIndex, offsetBy: 2)])).scanHexInt64(&red)
        // 绿
        Scanner(string: String(string[string.index(string.startIndex, offsetBy: 2)..<string.index(string.startIndex, offsetBy: 4)])).scanHexInt64(&green)
        // 蓝
        Scanner(string: String(string[string.index(string.startIndex, offsetBy: 4)...])).scanHexInt64(&blue)
        // 实例化
        self.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: alpha)
    }
    
    @objc convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
    
    @objc convenience init(all value: CGFloat, alpha: CGFloat = 1.0) {
        self.init(red: value/255.0, green: value/255.0, blue: value/255.0, alpha: alpha)
    }
}
