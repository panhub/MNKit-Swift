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
    
    /// 乱序数组
    mutating func scrambled() {
        guard count > 1 else { return }
        for index in 1..<count {
            let random = Int(arc4random_uniform(100000)) % index
            if random != index {
                swapAt(index, random)
            }
        }
    }
    
    /// 乱序数组
    /// - Returns: 乱序后的数组
    func scrambleArray() -> Array {
        var array = self
        array.scrambled()
        return array
    }
}

extension Array where Element: Equatable {
    
    /// 删除数组内相同元素
    /// - Returns: 删除相同元素后的数组
    func removeSameElement() -> [Element] {
        return reduce([Element]()) { $0.contains($1) ? $0: $0 + [$1] }
    }
    
    /// 删除数组内相同元素
    mutating func removeSame() {
        let result: [Element] = removeSameElement()
        removeAll()
        append(contentsOf: result)
    }
}

extension Array where Element: NSObject {
    
    /// 元素调用函数
    /// - Parameters:
    ///   - aSelector: 函数
    ///   - object1: 参数1
    ///   - object2: 参数2
    func makeObjectsPerform(_ aSelector: Selector, with object1: Any! = nil, with object2: Any! = nil) {
        for element in self {
            let _ = element.perform(aSelector, with: object1, with: object2)
        }
    }
}
