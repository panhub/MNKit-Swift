//
//  MNAssetAlbumBadge.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/30.
//  相簿

import UIKit

class MNAssetAlbumBadge: UIControl {
    // 标题
    private let label: UILabel = UILabel()
    // 显示箭头
    private let badgeView: UIView = UIView()
    // 箭头
    private let imageView: UIImageView = UIImageView()
    // 配置信息
    private let options: MNAssetPickerOptions
    // 是否可选择相册
    override var isEnabled: Bool {
        get { super.isEnabled }
        set {
            super.isEnabled = newValue
            backgroundColor = newValue ? (options.mode == .light ? UIColor(white: 0.0, alpha: 0.12) : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)) : .clear
            badgeView.isHidden = !newValue
            update(title: label.text)
        }
    }
    
    override var isSelected: Bool {
        get { imageView.transform != .identity }
        set {
            let transform: CGAffineTransform = newValue ? CGAffineTransform(rotationAngle: Double.pi).concatenating(CGAffineTransform(translationX: 0.0, y: -1.5)) : .identity
            UIView.animate(withDuration: 0.28, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self = self else { return }
                self.imageView.transform = transform
            }, completion: nil)
        }
    }
    
    init(options: MNAssetPickerOptions) {
        
        self.options = options
        
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0))
        
        super.isEnabled = false
        clipsToBounds = true
        backgroundColor = .clear
        layer.cornerRadius = bounds.height/2.0
        
        label.minX = 10.0
        label.numberOfLines = 1
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        label.textColor = options.mode == .light ? .black : UIColor(red: 251.0/255.0, green: 251.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        addSubview(label)
        
        badgeView.isHidden = true
        badgeView.size = CGSize(width: 20.0, height: 20.0)
        badgeView.midX = bounds.midX
        badgeView.midY = bounds.midY
        badgeView.layer.cornerRadius = badgeView.height/2.0
        badgeView.clipsToBounds = true
        badgeView.isUserInteractionEnabled = false
        badgeView.backgroundColor = options.mode == .light ? .white : UIColor(red: 166.0/255.0, green: 166.0/255.0, blue: 166.0/255.0, alpha: 1.0)
        addSubview(badgeView)
        
        imageView.size = CGSize(width: 11.0, height: 11.0)
        imageView.image = MNAssetPicker.image(named: "down")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.midX = badgeView.bounds.midX
        imageView.midY = badgeView.bounds.midY + 1.0
        imageView.isUserInteractionEnabled = false
        badgeView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**切换相簿*/
    func update(title: String?, animated: Bool = false, completion: (()->Void)? = nil) {
        let midX = center.x
        var size = ((title ?? "") as NSString).size(withAttributes: [.font:label.font!])
        size.width = ceil(size.width)
        size.height = ceil(size.height)
        var width: CGFloat = label.minX + size.width
        if badgeView.isHidden {
            width += label.minX
        } else {
            width += badgeView.bounds.width
            width += 12.0
        }
        width = max(width, bounds.height)
        label.text = title
        UIView.animate(withDuration: animated ? 0.3 : 0.0, delay: 0.0, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            self.width = width
            self.midX = midX
            self.label.size = size
            self.label.midY = self.bounds.midY
            self.badgeView.maxX = width - 5.0
        } completion: { _ in
            completion?()
        }
    }
}
