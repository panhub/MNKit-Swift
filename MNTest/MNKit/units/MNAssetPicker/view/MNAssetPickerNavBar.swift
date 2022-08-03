//
//  MNAssetPickerNavBar.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/30.
//  资源选择器顶部导航栏

import UIKit

protocol MNAssetPickerNavDelegate: NSObjectProtocol {
    /**关闭按钮点击事件*/
    func closeButtonTouchUpInside() -> Void
    /**相册按钮点击事件*/
    func albumButtonTouchUpInside(_ badge: MNAssetAlbumBadge) -> Void
}

class MNAssetPickerNavBar: UIView {
    /**相簿标记*/
    let badge: MNAssetAlbumBadge
    /**事件代理*/
    weak var delegate: MNAssetPickerNavDelegate?
    
    init(options: MNAssetPickerOptions) {
        
        badge = MNAssetAlbumBadge(options: options)
        
        super.init(frame: UIScreen.main.bounds.inset(by: UIEdgeInsets(top: 0.0, left: 0.0, bottom: UIScreen.main.bounds.height - options.topbarHeight, right: 0.0)))
        
        if options.mode == .light {
            backgroundColor = .white.withAlphaComponent(0.97)
        } else {
            backgroundColor = .clear
            let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            effectView.frame = bounds
            effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(effectView)
        }
        
        let top = options.isUsingFullScreenPresentation ? MN_STATUS_BAR_HEIGHT : 0.0
        
        let closeButton = UIButton(type: .custom)
        closeButton.minX = 15.0
        closeButton.size = CGSize(width: 24.0, height: 24.0)
        closeButton.midY = (height - top)/2.0 + top
        closeButton.setBackgroundImage(MNAssetPicker.image(named: "back")?.renderBy(color: options.mode == .light ? .black : UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButton(touchUpInside:)), for: .touchUpInside)
        addSubview(closeButton)
        
        badge.midX = bounds.width/2.0
        badge.midY = closeButton.midY
        badge.addTarget(self, action: #selector(badge(touchUpInside:)), for: .touchUpInside)
        addSubview(badge)
        
        let separator = UIView(frame: CGRect(x: 0.0, y: bounds.height - 0.7, width: bounds.width, height: 0.7))
        separator.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        separator.backgroundColor = options.mode == .light ? .gray.withAlphaComponent(0.15) : .black.withAlphaComponent(0.85)
        addSubview(separator)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Events
private extension MNAssetPickerNavBar {
    
    @objc func closeButton(touchUpInside sender: UIButton) {
        delegate?.closeButtonTouchUpInside()
    }
    
    @objc func badge(touchUpInside sender: MNAssetAlbumBadge) {
        delegate?.albumButtonTouchUpInside(sender)
    }
}
