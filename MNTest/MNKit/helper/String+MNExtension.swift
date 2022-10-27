//
//  String+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/15.
//

import UIKit
import Foundation
import CoreGraphics

extension String {
    // String => Bool
    var boolValue: Bool {
        switch self {
        case "1", "true", "yes", "YES", "y", "Y": return true
        default: return false
        }
    }
    // String => Int
    var intValue: Int { (self as NSString).integerValue }
    // String => Int64
    var int64Value: Int64 { (self as NSString).longLongValue }
    // String => Double
    var doubleValue: Double { (self as NSString).doubleValue }
}

// MARK: - 字符串截取
extension String {
    
    /// 自身范围
    var rangeOfAll: NSRange { NSRange(location: 0, length: count) }
    
    func sub(from index: Int) -> String {
        (self as NSString).substring(from: index)
    }
    
    func sub(to index: Int) -> String {
        (self as NSString).substring(to: index)
    }
    
    func sub(with range: NSRange) -> String {
        (self as NSString).substring(with: range)
    }
}

// MARK: - 计算尺寸
extension String {
    
    /// 计算文本尺寸
    /// - Parameter font: 字体
    /// - Returns: 尺寸
    func size(font: UIFont) -> CGSize {
        return (self as NSString).size(withAttributes: [.font:font])
    }
    
    /// 计算文本尺寸
    /// - Parameters:
    ///   - font: 字体
    ///   - bounding: 尺寸范围
    /// - Returns: 文本尺寸
    func size(font: UIFont, bounding: CGSize) -> CGSize {
        return (self as NSString).boundingRect(with:bounding , options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [.font: font], context: nil).size
    }
    
    /// 计算文本尺寸
    /// - Parameters:
    ///   - font: 字体
    ///   - width: 最大宽度
    /// - Returns: 文本尺寸
    func size(font: UIFont, width: CGFloat) -> CGSize {
        return size(font: font, bounding: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
    }
    
    /// 计算文本尺寸
    /// - Parameters:
    ///   - font: 字体
    ///   - height: 最大高度
    /// - Returns: 文本尺寸
    func size(font: UIFont, height: CGFloat) -> CGSize {
        return size(font: font, bounding: CGSize(width: CGFloat.greatestFiniteMagnitude, height: height))
    }
}

extension String {
    
    /// 倒叙字符串
    var reversed: String { String(reversed()) }
    
    /// 倒叙
    /// - Parameter separator: 分割符
    /// - Returns: 倒叙结果
    func reversed(separatedBy separator: String) -> String {
        let components = components(separatedBy: separator)
        return components.reversed().joined(separator: separator)
    }
    
    /// 可用的路径
    var pathAvailable: String {
        guard FileManager.default.fileExists(atPath: self) else { return self }
        let url: URL = URL(fileURLWithPath: self)
        let pathExtension = url.pathExtension
        var components = url.pathComponents
        guard components.count > 1 else { return self }
        let last = components.last!
        var name = pathExtension.count > 0 ? last.components(separatedBy: ".").first! : last
        let string = name.reversed
        let scanner: Scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = CharacterSet()
        if scanner.scanInt64(nil) {
            if scanner.isAtEnd {
                name = String(NSDecimalNumber(string: name).int64Value + 1)
            } else {
                var index: String.Index = string.startIndex
                if #available(iOS 13.0, *) {
                    index = scanner.currentIndex
                } else {
                    index = string.index(startIndex, offsetBy: scanner.scanLocation)
                }
                let substring: String = String(string[string.startIndex..<index])
                var endstring: String = ""
                if index == string.index(string.endIndex, offsetBy: -1) {
                    // 往后仅一个字符
                    endstring = String(string[index])
                } else {
                    endstring = String(string[index..<string.endIndex])
                }
                name = endstring.reversed + String(NSDecimalNumber(string: substring.reversed).int64Value + 1)
            }
        } else {
            name.append("2")
        }
        if pathExtension.count > 0 {
            name += ".\(pathExtension)"
        }
        components.removeLast()
        components.append(name)
        return components.joined(separator: "/").pathAvailable
    }
    
    /// 判断字符串是否全是数字
    var isAllNumber: Bool {
        guard count > 0 else { return false }
        let scanner: Scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = CharacterSet()
        return (scanner.scanInt64(nil) && scanner.isAtEnd)
    }
    
    /**唯一字符串*/
    static var identifier: String {
        "\(UIDevice.current.identifierForVendor?.uuidString ?? UIDevice.current.name)-\(UIDevice.current.systemVersion)-\(UUID().uuidString)-\(Int(Date().timeIntervalSince1970*1000.0))".md5
    }
}
