//
//  MNToast+Extension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/14.
//  Window弹窗

import UIKit
import Foundation

extension MNToast {
    @objc static var exist: Bool {
        guard let exist = window?.existToast else { return false }
        return exist
    }
    @objc static var window: UIWindow? {
        if #available(iOS 15.0, *) {
            return mainWindow(in: UIApplication.shared.delegate?.window??.windowScene?.windows.reversed())
        } else {
            return mainWindow(in: UIApplication.shared.windows.reversed())
        }
    }
    private static func mainWindow(in windows: [UIWindow]?) -> UIWindow? {
        guard let windows = windows else { return nil }
        for window in windows {
            let isOnMainScreen = window.screen == UIScreen.main
            let isVisible = (window.isHidden == false && window.alpha > 0.01)
            if isOnMainScreen, isVisible, window.isKeyWindow {
                return window
            }
        }
        return nil
    }
}

// MARK: - Window显示弹窗
extension MNToast {
    
    @objc class func show(_ status: String?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showToast(status: status)
        }
    }
    
    @objc class func showActivity(_ status: String?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showActivityToast(status)
        }
    }
    
    @objc class func showMask(_ status: String?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showMaskToast(status)
        }
    }
    
    @objc class func showMsg(_ status: String) {
        OperationQueue.main.addOperation {
            MNToast.window?.showMsgToast(status)
        }
    }
    
    @objc class func showMsg(_ status: String, completion: (()->Void)?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showMsgToast(status, completion: completion)
        }
    }
    
    @objc class func showInfo(_ status: String) {
        OperationQueue.main.addOperation {
            MNToast.window?.showInfoToast(status)
        }
    }
    
    @objc class func showInfo(_ status: String, completion: (()->Void)?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showInfoToast(status, completion: completion)
        }
    }
    
    @objc class func showComplete(_ status: String?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showCompleteToast(status)
        }
    }
    
    @objc class func showComplete(_ status: String?, completion: (()->Void)?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showCompleteToast(status, completion: completion)
        }
    }

    @objc class func showError(_ status: String?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showErrorToast(status)
        }
    }
    
    @objc class func showError(_ status: String?, completion: (()->Void)?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showErrorToast(status, completion: completion)
        }
    }
    
    @objc class func showProgress(_ status: String?) {
        OperationQueue.main.addOperation {
            MNToast.window?.showProgressToast(status)
        }
    }
}

// MARK: - Window更新弹窗
extension MNToast {
    @objc class func update(progress pro: Double) {
        OperationQueue.main.addOperation {
            MNToast.window?.updateToast(progress: pro)
        }
    }
    
    @objc class func update(status msg: String?) {
        OperationQueue.main.addOperation {
            MNToast.window?.updateToast(status: msg)
        }
    }
    
    @objc class func update(success completion:(()->Void)?) {
        OperationQueue.main.addOperation {
            MNToast.window?.updateToast(success: completion)
        }
    }
}

// MARK: - Window关闭弹窗
extension MNToast {
    @objc class func close() {
        OperationQueue.main.addOperation {
            MNToast.window?.closeToast()
        }
    }
    
    @objc class func close(completion: (()->Void)?) {
        OperationQueue.main.addOperation {
            MNToast.window?.closeToast(completion: completion)
        }
    }
}
