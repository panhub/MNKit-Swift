//
//  UIApplication+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/14.
//

import UIKit
import StoreKit
import Foundation
import CoreGraphics

#if !IN_APP_EXTENSIONS
public typealias MNApplicationOpenHandler = ((Bool) -> Void)

public extension UIApplication {
    
    enum StoreLoadMode {
        case inlay, skip
    }
    
    static func canOpenURL(_ url: MNURLConvertible?) -> Bool {
        guard let uRL = url?.urlValue else { return false }
        return UIApplication.shared.canOpenURL(uRL)
    }
    
    /**跳转指定链接*/
    static func handOpen(_ url: MNURLConvertible?, completion: MNApplicationOpenHandler? = nil) -> Void {
        guard let uRL = url?.urlValue else {
            completion?(false)
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(uRL, options: [:], completionHandler: completion)
        } else {
            if UIApplication.shared.canOpenURL(uRL) {
                let result = UIApplication.shared.openURL(uRL)
                completion?(result)
            } else {
                completion?(false)
            }
        }
    }
    
    static func openQQ(user: String, completion: MNApplicationOpenHandler? = nil) -> Void {
        handOpen("mqq://im/chat?chat_type=wpa&uin=\(user)&version=1&src_type=web", completion: completion)
    }
    
    static func openQQ(group: String, key: String, completion: MNApplicationOpenHandler? = nil) -> Void {
        handOpen("mqqapi://card/show_pslcard?src_type=internal&version=1&uin=\(group)&key=\(key)&card_type=group&source=external", completion: completion)
    }
    
    static func openScore(_ appId: String, mode: StoreLoadMode = .skip, completion: MNApplicationOpenHandler? = nil) {
        guard appId.count > 0 else {
            completion?(false)
            return
        }
        UIWindow.current?.endEditing(true)
        if mode == .inlay {
            if #available(iOS 14.0, *) {
                if let windowScene = UIApplication.shared.delegate?.window??.windowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                    return
                }
            } else if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
                return
            }
        }
        let url: String = "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review"
        handOpen(url, completion: completion)
    }
}

extension UIApplication {
    
    /// 询问状态栏的方向
    /// - Returns: 状态栏的方向
    @objc static func statusBarOrientation() -> UIInterfaceOrientation {
        var orientation: UIInterfaceOrientation = .unknown
        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.delegate?.window??.windowScene {
                orientation = scene.interfaceOrientation
            }
        } else {
            orientation = UIApplication.shared.statusBarOrientation
        }
        return orientation
    }
    
    /// 询问状态栏的样式
    /// - Returns: 状态栏样式
    @objc static func statusBarStyle() -> UIStatusBarStyle {
        var style: UIStatusBarStyle = .default
        if #available(iOS 13.0, *) {
            if let statusBarManager = UIApplication.shared.delegate?.window??.windowScene?.statusBarManager {
                style = statusBarManager.statusBarStyle
            }
        } else {
            style = UIApplication.shared.statusBarStyle
        }
        return style
    }
    
    /// 询问状态栏是否隐藏
    /// - Returns: 状态栏是否隐藏
    @objc static func isStatusBarHidden() -> Bool {
        var isHidden: Bool = false
        if #available(iOS 13.0, *) {
            if let statusBarManager = UIApplication.shared.delegate?.window??.windowScene?.statusBarManager {
                isHidden = statusBarManager.isStatusBarHidden
            }
        } else {
            isHidden = UIApplication.shared.isStatusBarHidden
        }
        return isHidden
    }
    
    /// 询问状态栏位置
    /// - Returns: 状态栏位置
    @objc static func statusBarFrame() -> CGRect {
        var rect: CGRect = .zero
        if #available(iOS 13.0, *) {
            if let statusBarManager = UIApplication.shared.delegate?.window??.windowScene?.statusBarManager {
                rect = statusBarManager.statusBarFrame
            }
        } else {
            rect = UIApplication.shared.statusBarFrame
        }
        return rect
    }
}
#endif
