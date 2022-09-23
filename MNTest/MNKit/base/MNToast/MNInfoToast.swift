//
//  MNInfoToast.swift
//  MNFoundation
//  
//  Created by 冯盼 on 2022/1/14.
//

import UIKit

class MNInfoToast: MNToast {

    override func createView() {
        super.createView()
        
        let imageView = UIImageView(image: MNToast.image(named: "info")?.withRenderingMode(.alwaysTemplate))
        imageView.frame = CGRect(x: 0.0, y: 0.0, width: 45.0, height: 45.0)
        imageView.tintColor = Self.tintColor
        imageView.contentMode = .scaleAspectFit
        container.frame = imageView.frame
        container.addSubview(imageView)
    }
    
    override func start() {
        contentView.alpha = 0.0
        contentView.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
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
        Self.self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.stop), object: nil)
        self.perform(#selector(self.stop), with: nil, afterDelay: MNToast.duration(status: msg))
    }
    
    override func cancel() {
        Self.self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.stop), object: nil)
    }
}
