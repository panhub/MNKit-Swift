//
//  Application+MNHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/2.
//  对网络请求视图调用

import UIKit
import Foundation
import ObjectiveC.runtime

@available(iOSApplicationExtension, unavailable, message: "This is NS_EXTENSION_UNAVAILABLE_IOS")
public extension UIApplication {
    private struct AssociatedKey {
        static var activityCount = "com.mn.application.activity.count"
    }
    /**活跃次数*/
    fileprivate var activityCount: Int {
        get { return objc_getAssociatedObject(self, &AssociatedKey.activityCount) as? Int ?? 0 }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.activityCount, newValue, .OBJC_ASSOCIATION_ASSIGN)
            if #available(iOS 13.0, *) {
                /// 建议自定义网络指示图
            } else {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = newValue > 0
                }
            }
        }
    }
    
    @objc static func startNetworkActivityIndicating() -> Void {
        UIApplication.shared.activityCount = UIApplication.shared.activityCount + 1
    }
    
    @objc static func closeNetworkActivityIndicating() -> Void {
        UIApplication.shared.activityCount = max(0, UIApplication.shared.activityCount - 1)
    }
}
