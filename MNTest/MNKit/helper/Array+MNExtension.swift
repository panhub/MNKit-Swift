//
//  Array+MNExtension.swift
//  anhe
//
//  Created by 冯盼 on 2022/6/4.
//  数组扩展

import Foundation

extension Array {
    
    /// 遍历元素
    /// - Parameter block: 回调外界使用
    func enumElement(_ block: (Element, Int, UnsafeMutablePointer<Bool>) -> Void) {
        guard count > 0 else { return }
        var stop: Bool = false
        for idx in 0..<count {
            block(self[idx], idx, &stop)
            guard stop == false else { break }
        }
    }
}

/// 删除数组内重复元素
extension Array where Element: Equatable {
    
    func removeSameElement() -> [Element] {
        return reduce([Element]()) { $0.contains($1) ? $0: $0 + [$1] }
    }
    
    mutating func removeSame() {
        let result: [Element] = removeSameElement()
        removeAll()
        append(contentsOf: result)
    }
}

/// 删除数组内重复元素
extension Array where Element: NSObject {
    
    func makeObjectsPerform(_ aSelector: Selector, with anArgument: Any? = nil) {
        if let arg = anArgument {
            for element in self {
                let _ = element.perform(aSelector, with: arg)
            }
        } else {
            for element in self {
                let _ = element.perform(aSelector)
            }
        }
    }
}
