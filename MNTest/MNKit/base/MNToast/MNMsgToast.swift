//
//  MNMsgToast.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/10.
//  提示信息

import UIKit

class MNMsgToast: MNToast {
    
    override var isAllowsUserInteraction: Bool { false }

    override func createView() {
        super.createView()
    }
    
    override func updateSubviews() {
        label.attributedText = string
        var size = label.attributedText!.boundingRect(with: CGSize(width: 200.0, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).size
        size.width = ceil(size.width)
        size.height = ceil(size.height)
        label.size = size
        contentView.width = ceil(label.width + min(Self.contentInset.left, Self.contentInset.right)*2.0)
        contentView.height = ceil(label.height + min(Self.contentInset.top, Self.contentInset.bottom)*2.0)
        label.center = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
        update()
    }
    
    override func start() {
        contentView.alpha = 0.0
        contentView.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
        UIView.animate(withDuration: Self.fadeAnimationDuration) { [weak self] in
            self?.contentView.alpha = 1.0
            self?.contentView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.perform(#selector(self.stop), with: nil, afterDelay: MNToast.duration(status: self.string?.string))
        }
    }
    
    override func stop() {
        UIView.animate(withDuration: Self.fadeAnimationDuration, delay: 0.0, options: .curveEaseOut) { [weak self] in
            self?.contentView.alpha = 0.0
            self?.contentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { [weak self] finish in
            guard let self = self else { return }
            self.removeFromSuperview()
        }
    }
    
    override func update(status msg: String?) {
        super.update(status: msg)
        // 计算时间
        Self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.stop), object: nil)
        self.perform(#selector(self.stop), with: nil, afterDelay: MNToast.duration(status: msg))
    }
    
    override func cancel() {
        Self.self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.stop), object: nil)
    }
}
