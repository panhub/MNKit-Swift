//
//  UIDevice+MNExtension.swift
//  anhe
//
//  Created by 冯盼 on 2022/3/30.
//  设备管理

import UIKit
import Foundation

extension UIDevice {
    
    /// 是否为iPhone
    static let isPhone: Bool = {
        UIDevice.current.userInterfaceIdiom == .phone
    }()
    
    /// 是否为iPad
    static let isPad: Bool = {
        UIDevice.current.userInterfaceIdiom == .pad
    }()
    
    /// 系统版本号
    var version: Double { NSDecimalNumber(string: systemVersion).doubleValue }
    
    /// 是否为越狱设备
    static let isBreakDevice: Bool = {
        if let _ = getenv("DYLD_INSERT_LIBRARIES") { return true }
        let paths: [String] = ["/Applications/Cydia.app", "/Library/MobileSubstrate/MobileSubstrate.dylib", "/bin/bash", "/usr/sbin/sshd", "/etc/apt"]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        if let url = URL(string: "cydia://"), UIApplication.shared.canOpenURL(url) { return true }
        if FileManager.default.fileExists(atPath: "User/Applications/"), let contents = FileManager.default.contents(atPath: "User/Applications/"), contents.count > 0 { return true }
        return false
    }()
    
    /// 旋转设备到指定用户界面
    /// - Parameter orientation: 用户界面方向
    func rotationToInterfaceOrientation(_ orientation: UIInterfaceOrientation) {
        guard let deviceOrientation = UIDeviceOrientation(rawValue: orientation.rawValue) else { return }
        rotationToDeviceOrientation(deviceOrientation)
    }
    
    /// 旋转设备到指定设备方向
    /// - Parameter orientation: 设备方向
    func rotationToDeviceOrientation(_ orientation: UIDeviceOrientation) {
        guard self.orientation != orientation else { return }
        setValue(orientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    /// 设备型号
    /// https://www.theiphonewiki.com/wiki/Models
    static let deviceModel: String = {
        var systemInfo: utsname = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        switch identifier {
        case "i386", "x86_64": return "Simulator"
        case "iPhone1,1": return "iPhone"
        case "iPhone1,2": return "iPhone 3G"
        case "iPhone2,1": return "iPhone 3GS"
        case "iPhone3,1": return "iPhone 4"
        case "iPhone3,2": return "iPhone 4"
        case "iPhone3,3": return "iPhone 4"
        case "iPhone4,1": return "iPhone 4S"
        case "iPhone5,1": return "iPhone 5"
        case "iPhone5,2": return "iPhone 5 (GSM+CDMA)"
        case "iPhone5,3": return "iPhone 5C (GSM)"
        case "iPhone5,4": return "iPhone 5C (GSM+CDMA)"
        case "iPhone6,1": return "iPhone 5S (GSM)"
        case "iPhone6,2": return "iPhone 5S (GSM+CDMA)"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone7,2": return "iPhone 6"
        case "iPhone8,1": return "iPhone 6S"
        case "iPhone8,2": return "iPhone 6S Plus"
        case "iPhone8,4": return "iPhone SE"
        case "iPhone9,1": return "iPhone 7"
        case "iPhone9,2": return "iPhone 7 Plus"
        case "iPhone9,3": return "iPhone 7"
        case "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1": return "iPhone 8"
        case "iPhone10,2": return "iPhone 8 Plus"
        case "iPhone10,3": return "iPhone X"
        case "iPhone10,4": return "iPhone 8"
        case "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4": return "iPhone XS Max"
        case "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone13,1": return "iPhone 12 Mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 Mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPad1,1": return "iPad"
        case "iPad1,2": return "iPad 3G"
        case "iPad2,1": return "iPad 2 (WiFi)"
        case "iPad2,2": return "iPad 2"
        case "iPad2,3": return "iPad 2 (CDMA)"
        case "iPad2,4": return "iPad 2"
        case "iPad2,5": return "iPad Mini (WiFi)"
        case "iPad2,6": return "iPad Mini"
        case "iPad2,7": return "iPad Mini (GSM+CDMA)"
        case "iPad3,1": return "iPad 3 (WiFi)"
        case "iPad3,2": return "iPad 3 (GSM+CDMA)"
        case "iPad3,3": return "iPad 3"
        case "iPad3,4": return "iPad 4 (WiFi)"
        case "iPad3,5": return "iPad 4"
        case "iPad3,6": return "iPad 4 (GSM+CDMA)"
        case "iPad4,1": return "iPad Air (WiFi)"
        case "iPad4,2": return "iPad Air (Cellular)"
        case "iPad4,4": return "iPad Mini 2 (WiFi)"
        case "iPad4,5": return "iPad Mini 2 (Cellular)"
        case "iPad4,6": return "iPad Mini 2"
        case "iPad4,7": return "iPad Mini 3"
        case "iPad4,8": return "iPad Mini 3"
        case "iPad4,9": return "iPad Mini 3"
        case "iPad5,1": return "iPad Mini 4 (WiFi)"
        case "iPad5,2": return "iPad Mini 4 (LTE)"
        case "iPad5,3": return "iPad Air 2"
        case "iPad5,4": return "iPad Air 2"
        case "iPad6,3": return "iPad Pro (9.7 inch)"
        case "iPad6,4": return "iPad Pro (9.7 inch)"
        case "iPad6,7": return "iPad Pro (12.9 inch)"
        case "iPad6,8": return "iPad Pro (12.9 inch)"
        case "iPad6,11": return "iPad 5 (WiFi)"
        case "iPad6,12": return "iPad 5 (Cellular)"
        case "iPad7,1": return "iPad Pro (12.9 inch) (2nd generation) (WiFi)"
        case "iPad7,2": return "iPad Pro (12.9 inch) (2nd generation) (Cellular)"
        case "iPad7,3": return "iPad Pro (10.5 inch) (WiFi)"
        case "iPad7,4": return "iPad Pro (10.5 inch) (Cellular)"
        case "iPad7,5": return "iPad (6th generation)"
        case "iPad7,6": return "iPad (6th generation)"
        case "iPad7,11": return "iPad (7th generation)"
        case "iPad7,12": return "iPad (7th generation)"
        case "iPad8,1": return "iPad Pro (11 inch)"
        case "iPad8,2": return "iPad Pro (11 inch)"
        case "iPad8,3": return "iPad Pro (11 inch)"
        case "iPad8,4": return "iPad Pro (11 inch)"
        case "iPad8,5": return "iPad Pro (12.9 inch) (3rd generation)"
        case "iPad8,6": return "iPad Pro (12.9 inch) (3rd generation)"
        case "iPad8,7": return "iPad Pro (12.9 inch) (3rd generation)"
        case "iPad8,8": return "iPad Pro (12.9 inch) (3rd generation)"
        case "iPad8,9": return "iPad Pro (11 inch) (2nd generation)"
        case "iPad8,10": return "iPad Pro (11 inch) (2nd generation)"
        case "iPad8,11": return "iPad Pro (12.9 inch) (4th generation)"
        case "iPad8,12": return "iPad Pro (12.9 inch) (4th generation)"
        case "iPad11,1": return "iPad Mini (5th generation)"
        case "iPad11,2": return "iPad Mini (5th generation)"
        case "iPad11,3": return "iPad Air (3rd generation)"
        case "iPad11,4": return "iPad Air (3rd generation)"
        case "iPad11,6": return "iPad (8th generation)"
        case "iPad11,7": return "iPad (8th generation)"
        case "iPad12,1": return "iPad (9th generation)"
        case "iPad12,2": return "iPad (9th generation)"
        case "iPad13,1": return "iPad Air (4th generation)"
        case "iPad13,2": return "iPad Air (4th generation)"
        case "iPad13,16": return "iPad Air (5th generation)"
        case "iPad13,17": return "iPad Air (5th generation)"
        case "iPad14,1": return "iPad Mini (6th generation)"
        case "iPad14,2": return "iPad Mini (6th generation)"
        default: return identifier
        }
    }()
}

public func IOS_VERSION_EQUAL(_ version: Double) -> Bool {
    return UIDevice.current.version == version
}

public func IOS_VERSION_EQUAL(_ version: CGFloat) -> Bool {
    return CGFloat(UIDevice.current.version) == version
}

public func IOS_VERSION_LATER(_ version: Double) -> Bool {
    return UIDevice.current.version > version
}

public func IOS_VERSION_LATER(_ version: CGFloat) -> Bool {
    return CGFloat(UIDevice.current.version) > version
}

public func IOS_VERSION_UNDER(_ version: Double) -> Bool {
    return UIDevice.current.version < version
}

public func IOS_VERSION_UNDER(_ version: CGFloat) -> Bool {
    return CGFloat(UIDevice.current.version) < version
}
