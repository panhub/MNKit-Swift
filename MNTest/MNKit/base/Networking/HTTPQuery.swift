//
//  MNURLQuery.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/19.
//  链接参数提取

import Foundation
import CoreGraphics

fileprivate class MNQueryPair {
    fileprivate var field: String?
    fileprivate var value: String?
    fileprivate var stringValue: String? {
        guard let field = MNQueryEncoding(field), field.count > 0, let value = MNQueryEncoding(value) else { return nil }
        return "\(field)=\(value)"
    }
}

// 参数提取
public func MNQueryExtract(_ query: Any?) -> String? {
    return MNQueryStringExtract(query, "&")
}

public func MNQueryStringExtract(_ query: Any?, _ separator: String) -> String? {
    guard let obj = query else { return nil }
    // 字符串直接编码
    if let string = obj as? String {
        return MNQueryEncoding(string)
    }
    // 字典
    if let item = obj as? [String: Any] {
        if let pairs = MNQueryPairExtract(item) {
            let result: [String] = pairs.compactMap { $0.stringValue }
            return result.count > 0 ? result.joined(separator: separator) : nil
        }
    }
    // 拒绝其他类型
    return nil
}

fileprivate func MNQueryPairExtract(_ item: [String: Any]) -> [MNQueryPair]? {
    var pairs = [MNQueryPair]()
    for (key, value) in item {
        let pair = MNQueryPair()
        pair.field = key
        if value is String {
            pair.value = (value as? String)!
        } else if (value is Int || value is Double || value is CGFloat || value is Float || value is Int64 || value is Int32 || value is Int16 || value is Int8 || value is Float32 || value is Float64) {
            pair.value = "\(value)"
        } else if value is Bool {
            pair.value = (value as! Bool) ? "1" : "0"
        } else if value is ObjCBool {
            pair.value = (value as! ObjCBool).boolValue ? "1" : "0"
        } else if value is NSNumber {
            pair.value = (value as! NSNumber).stringValue
        } else if #available(iOS 14.0, *), value is Float16 {
            pair.value = "\(value)"
        }
        pairs.append(pair)
    }
    return pairs.count > 0 ? pairs : nil
}

// 参数编码
fileprivate let MNQueryEncodeBatchLength = 50
fileprivate let MNQueryEncodeDelimiters: String = ":#[]@!$&'()*+,;="
public func MNQueryEncoding(_ string: String?) -> String? {
    guard let query = string else { return nil }
    // 利用NSString编码
    let string = query as NSString
    // 定义通用编码字符集
    var allowedCharacterSet = NSCharacterSet.urlQueryAllowed
    allowedCharacterSet.remove(charactersIn: MNQueryEncodeDelimiters)
    // 分段编码
    var index: Int = 0
    var result: String = ""
    while index < query.count {
        let length = min(query.count - index, MNQueryEncodeBatchLength)
        var range = NSRange(location: index, length: length)
        // 避免表情分割
        range = string.rangeOfComposedCharacterSequences(for: range)
        guard let sub = string.substring(with: range).addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) else { return nil }
        result.append(sub)
        index += range.length
    }
    return result
}

