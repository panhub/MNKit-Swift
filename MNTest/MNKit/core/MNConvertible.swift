//
//  MNEnum.swift
//  TLChat
//
//  Created by 冯盼 on 2022/8/1.
//  核心协议

import UIKit
import Foundation
import ObjectiveC.runtime

// MARK: - MNURLConvertible
public protocol MNURLConvertible {}
extension URL: MNURLConvertible {}
extension String: MNURLConvertible {}
extension MNURLConvertible {
    
    var urlValue: URL? {
        if self is URL {
            return self as? URL
        } else if self is String {
            let string = self as! String
            if string.hasPrefix("file") || (string as NSString).isAbsolutePath {
                return URL(fileURLWithPath: string)
            }
            return URL(string: string)
        }
        return nil
    }
    
    var stringValue: String? {
        if self is String {
            return self as? String
        } else if self is URL {
            let url = self as! URL
            if url.isFileURL {
                return url.path
            }
            return url.absoluteString
        }
        return nil
    }
}

// MARK: - MNBadgeConvertible
public protocol MNBadgeConvertible {}
extension Int: MNBadgeConvertible {}
extension String: MNBadgeConvertible {}
extension MNBadgeConvertible {
    
    var stringValue: String {
        var value: String = ""
        if self is String {
            value = self as! String
        } else if self is Int {
            value = NSNumber(value: self as! Int).stringValue
        }
        return value
    }
    
    var intValue: Int {
        var value: Int = 0
        if self is Int {
            value = self as! Int
        } else if self is String {
            value = ((self as! String) as NSString).integerValue
        }
        return value
    }
}

// MARK: - MNAttributedStringConvertible
public protocol MNAttributedStringConvertible {}
extension String: MNAttributedStringConvertible {}
extension NSAttributedString: MNAttributedStringConvertible {}
extension MNAttributedStringConvertible {
    
    var string: String {
        if self is String {
            return self as! String
        }
        return (self as! NSAttributedString).string
    }
    
    func attributedString(font: UIFont, color: UIColor = .black) -> NSAttributedString {
        if self is NSAttributedString {
            return self as! NSAttributedString
        }
        return NSAttributedString(string: self as! String, attributes: [.font:font, .foregroundColor: color])
    }
}

// MARK: - MNSwizzleConvertible
@objc public protocol MNSwizzleConvertible: NSObjectProtocol {}
extension MNSwizzleConvertible {
    
    // 交换实例方法
    func replacingMethod(_ originalSelector: Selector, _ swizzledSelector: Selector) -> Void {
        if let originalMethod = class_getInstanceMethod(Self.self, originalSelector), let swizzledMethod = class_getInstanceMethod(Self.self, swizzledSelector)  {
            if class_addMethod(Self.self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
                class_replaceMethod(Self.self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    // 交换类方法
    static func replacingClassMethod(_ originalSelector: Selector, _ swizzledSelector: Selector) -> Void {
        // 类方法列表存放在元类里, 这里要获取元类
        let metaClass: AnyClass? = objc_getMetaClass(object_getClassName(Self.self)) as? AnyClass
        if let originalMethod = class_getClassMethod(metaClass, originalSelector), let swizzledMethod = class_getClassMethod(metaClass, swizzledSelector) {
            if class_addMethod(metaClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
                class_replaceMethod(metaClass, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    }
}

public protocol MNCalculateConvertible  {}
extension Int: MNCalculateConvertible {}
extension Double: MNCalculateConvertible {}
extension CGFloat: MNCalculateConvertible {}
extension MNCalculateConvertible {
    
    /// =>Int
    var intValue: Int {
        if self is Int {
            return self as! Int
        } else if self is Double {
            return Int(self as! Double)
        } else if self is CGFloat {
            return Int(self as! CGFloat)
        }
        return 0
    }
    
    /// =>Double
    var doubleValue: Double {
        if self is Double {
            return self as! Double
        } else if self is Int {
            return Double(self as! Int)
        } else if self is CGFloat {
            return Double(self as! CGFloat)
        }
        return 0.0
    }
    
    /// =>CGFloat
    var floatValue: CGFloat {
        if self is CGFloat {
            return self as! CGFloat
        } else if self is Double {
            return CGFloat(self as! Double)
        } else if self is Int {
            return CGFloat(self as! Int)
        }
        return 0.0
    }
    
    /// =>NSDecimalNumber
    var numberValue: NSDecimalNumber {
        if self is Int {
            return NSDecimalNumber(value: self as! Int)
        } else if self is Double {
            return NSDecimalNumber(value: self as! Double)
        } else if self is CGFloat {
            return NSDecimalNumber(value: self as! CGFloat)
        }
        return NSDecimalNumber(value: 0)
    }
    
    /// 精确小数位
    /// - Parameters:
    ///   - mode: 精确模式
    ///   - scale: 精度
    /// - Returns: 计算结果
    func decimal(mode: NSDecimalNumber.RoundingMode, scale: Int) -> NSDecimalNumber {
        let behavior: NSDecimalNumberHandler = NSDecimalNumberHandler(roundingMode: mode, scale: Int16(scale), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return numberValue.dividing(by: NSDecimalNumber(value: 1), withBehavior: behavior)
    }
}
