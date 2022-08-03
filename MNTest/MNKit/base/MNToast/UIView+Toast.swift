//
//  UIView+Toast.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/10.
//  弹窗管理

import UIKit
import ObjectiveC.runtime

// MARK: - 获取弹窗
extension UIView {
    
    @objc var existToast: Bool {
        guard let _ = toast else { return false }
        return true
    }
    
    private var toast: MNToast? {
        return objc_getAssociatedObject(self, &MNToast.AssociatedKey.toast) as? MNToast
    }
}

// MARK: - 显示弹窗
extension UIView {
    
    @objc func showToast(status: String?) {
        let _ = show(toast: .mask, status: status)
    }
    
    @objc func showActivityToast(_ status: String?) {
        let _ = show(toast: .activity, status: status)
    }
    
    @objc func showMaskToast(_ status: String?) {
        let _ = show(toast: .mask, status: status)
    }
    
    @objc func showShapeToast(_ status: String?) {
        let _ = show(toast: .shape, status: status)
    }
    
    @objc func showMsgToast(_ status: String) {
        showMsgToast(status, completion: nil)
    }
    
    @objc func showMsgToast(_ status: String, completion: (()->Void)?) {
        if show(toast: .message, status: status), let _ = completion {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + MNToast.duration(status: status) + MNToast.fadeAnimationDuration + 0.1, execute: completion!)
        }
    }
    
    @objc func showInfoToast(_ status: String) {
        showInfoToast(status, completion: nil)
    }
    
    @objc func showInfoToast(_ status: String, completion: (()->Void)?) {
        if show(toast: .info, status: status), let _ = completion {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + MNToast.duration(status: status) + MNToast.fadeAnimationDuration + 0.1, execute: completion!)
        }
    }
    
    @objc func showCompleteToast(_ status: String?) {
        showCompleteToast(status, completion: nil)
    }
    
    @objc func showCompleteToast(_ status: String?, completion: (()->Void)?) {
        if show(toast: .complete, status: status), let _ = completion {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + MNToast.duration(status: status) + MNToast.fadeAnimationDuration + 0.1, execute: completion!)
        }
    }
    
    @objc func showErrorToast(_ status: String?) {
        showErrorToast(status, completion: nil)
    }
    
    @objc func showErrorToast(_ status: String?, completion: (()->Void)?) {
        if show(toast: .error, status: status), let _ = completion {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + MNToast.duration(status: status) + MNToast.fadeAnimationDuration + 0.1, execute: completion!)
        }
    }
    
    @objc func showProgressToast(_ status: String?) {
        showProgressToast(status, progress: 0.0)
    }
    
    @objc func showProgressToast(_ status: String?, progress: CGFloat) {
        if let dialog = toast {
            if dialog.style == .progress {
                dialog.update(status: status)
                (dialog as! MNProgressToast).update(progress: progress)
                return
            }
            dialog.cancel()
            dialog.removeFromSuperview()
        }
        if let dialog = MNToast.toast(style: .progress, status: status) {
            dialog.show(in: self)
        }
    }
    
    private func show(toast style: MNToast.ToastStyle, status: String?) -> Bool {
        if let dialog = toast {
            if dialog.style == style {
                dialog.update(status: status)
                return true
            }
            dialog.cancel()
            dialog.removeFromSuperview()
        }
        if let dialog = MNToast.toast(style: style, status: status) {
            dialog.show(in: self)
            return true
        }
        return false
    }
}

// MARK: - 更新弹窗
extension UIView {
    
    @objc func updateToast(status: String?) {
        guard let dialog = toast else { return }
        dialog.update(status: status)
    }
    
    @objc func updateToast(progress: CGFloat) {
        guard let dialog = toast, dialog.style == .progress else { return }
        (dialog as! MNProgressToast).update(progress: progress)
    }
    
    @objc func updateToast(success completion:(()->Void)?) {
        guard let dialog = toast, dialog.style == .progress else { return }
        (dialog as! MNProgressToast).success()
        if let _ = completion {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2 + MNToast.fadeAnimationDuration + 0.1, execute: completion!)
        }
    }
}

// MARK: - 关闭弹窗
extension UIView {
    @objc func closeToast() {
        closeToast(completion: nil)
    }
    
    @objc func closeToast(completion: (()->Void)?) {
        guard let dialog = toast else { return }
        dialog.cancel()
        guard let _ = completion else {
            dialog.removeFromSuperview()
            return
        }
        switch dialog.style {
        case .message, .complete, .error, .progress, .info:
            dialog.stop()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + MNToast.fadeAnimationDuration + 0.15, execute: completion!)
        default:
            dialog.removeFromSuperview()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.15, execute: completion!)
        }
    }
}
