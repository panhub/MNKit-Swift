//
//  MNHelper.swift
//  TLChat
//
//  Created by 冯盼 on 2022/8/2.
//  核心扩展方法

import UIKit
import Foundation
import CoreGraphics

// MARK: - UIApplication
public extension UIApplication {
    
    /// 状态栏高度
    @objc static let StatusBarHeight: CGFloat = {
        if #available(iOS 13.0, *) {
            if let statusBarManager = UIApplication.shared.delegate?.window??.windowScene?.statusBarManager {
                return statusBarManager.statusBarFrame.height
            } else {
                return 0.0
            }
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }()
}

// MARK: - UITabBar
public extension UITabBar {
    
    /// 标签栏高度
    static let Height: CGFloat = {
        var height: CGFloat = 0.0
        if Thread.isMainThread {
            height = UITabBarController().tabBar.frame.height
        } else {
            DispatchQueue.main.sync {
                height = UITabBarController().tabBar.frame.height
            }
        }
        return height
    }()
}

// MARK: - UINavigationBar
public extension UINavigationBar {
    
    /// 导航栏高度
    @objc static let Height: CGFloat = {
        var height: CGFloat = 0.0
        if Thread.isMainThread {
            height = UINavigationController().navigationBar.frame.height
        } else {
            DispatchQueue.main.sync {
                height = UINavigationController().navigationBar.frame.height
            }
        }
        return height
    }()
}

// MARK: - UIWindow
public extension UIWindow {
    
    /// 安全区域
    static let Safe: UIEdgeInsets = {
        var inset: UIEdgeInsets = .zero
        if #available(iOS 11.0, *) {
            if Thread.isMainThread {
                inset = UIWindow().safeAreaInsets
            } else {
                DispatchQueue.main.sync {
                    inset = UIWindow().safeAreaInsets
                }
            }
        }
        return inset
    }()
}

// MARK: - UIScreen
public extension UIScreen {
    /// 屏幕宽
    static var Width: CGFloat { UIScreen.main.bounds.width }
    /// 屏幕高
    static var Height: CGFloat { UIScreen.main.bounds.height }
    /// 屏幕宽/高最小值
    static let Min = min(Width, Height)
    /// 屏幕宽/高最大值
    static let Max = max(Width, Height)
}

// MARK: - Bundle
public extension Bundle {
    
    /// 构造资源束
    /// - Parameter name: 名称
    @objc convenience init?(name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: "bundle") else { return nil }
        self.init(path: path)
    }
    
    /// 获取资源束内图片
    /// - Parameters:
    ///   - name: 图片名
    ///   - ext: 扩展名
    ///   - subpath: 所在文件夹
    /// - Returns: 图片
    func image(named name: String, type ext: String = "png", directory subpath: String? = nil) -> UIImage? {
        let imageName: String = name.contains("@") ? name : "\(name)@\(Int(UIScreen.main.scale))x"
        var path: String? = path(forResource: imageName, ofType: ext, inDirectory: subpath)
        if path == nil, name.contains("@") == false {
            var scale: Int = 3
            while scale > 0 {
                if let result = self.path(forResource: "\(name)@\(scale)x", ofType: ext, inDirectory: subpath) {
                    path = result
                    break
                }
                scale -= 1
            }
        }
        guard let imagePath = path else { return nil }
        return UIImage(contentsOfFile: imagePath)
    }
}
