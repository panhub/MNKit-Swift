//
//  String+MNSubscript.swift
//  anhe
//
//  Created by 冯盼 on 2022/2/27.
//  截取字符串

import Foundation

extension String {
    
    /// 根据下标获取字符串
    subscript(of index: Int) -> String {
        guard index >= 0, index < count else { return "" }
        return String(self[self.index(startIndex, offsetBy: index)])
    }
    
    /// 根据闭区间获取字符串 eg: a[1...3]
    subscript(range: ClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(range.lowerBound, 0))
        let end = index(startIndex, offsetBy: min(range.upperBound, count - 1))
        return String(self[start...end])
    }
    
    /// 根据半开半闭区间获取字符串 eg: a[1..<3]
    subscript(range: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: max(range.lowerBound, 0))
        let end = index(startIndex, offsetBy: min(range.upperBound, count))
        return String(self[start..<end])
    }
    
    /// 根据半区间获取字符串 eg: a[...2]
    subscript(range: PartialRangeThrough<Int>) -> String {
        let end = index(startIndex, offsetBy: min(range.upperBound, count - 1))
        return String(self[startIndex...end])
    }
    
    /// 根据半区间获取字符串 eg: a[0...]
    subscript(range: PartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(range.lowerBound, 0))
        let end = index(startIndex, offsetBy: count - 1)
        return String(self[start...end])
    }
    
    /// 根据半区间获取字符串 eg: a[..<3]
    subscript(range: PartialRangeUpTo<Int>) -> String {
        let end = index(startIndex, offsetBy: min(range.upperBound, count))
        return String(self[startIndex..<end])
    }
}

extension String {
    
    /// 截取字符串
    /// - Parameter location: 起始下标
    /// - Returns: 截取后的字符串
    func substring(fromIndex location: Int) -> String {
        guard count > 0, location >= 0, location < count else { return "" }
        let start = index(startIndex, offsetBy: location)
        return String(self[start..<endIndex])
    }
    
    /// 截取字符串
    /// - Parameter location: 结束下标
    /// - Returns: 截取后的字符串
    func substring(toIndex location: Int) -> String {
        guard count > 0, location > 0 else { return "" }
        let end = index(startIndex, offsetBy: min(count - 1, location))
        return String(self[startIndex...end])
    }
    
    /// 截取字符串
    /// - Parameters:
    ///   - location: 起始位置
    ///   - length: 长度
    /// - Returns: 截取后的字符串
    func substring(location: Int, count length: Int) -> String {
        guard count > 0, location >= 0, length > 0 else { return "" }
        let start = index(startIndex, offsetBy: location)
        let end = index(startIndex, offsetBy: min(count, location + length))
        return String(self[start..<end])
    }
}
