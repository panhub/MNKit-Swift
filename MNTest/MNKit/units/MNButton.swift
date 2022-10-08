//
//  MNButton.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/13.
//  自定义按钮

import UIKit

class MNButton: UIControl {
    
    /// 布局位置
    enum Placement: Int {
        case leading, trailing
    }
    
    /// 标题
    let titleLabel: UILabel = UILabel()
    /// 图片
    let imageView: UIImageView = UIImageView()
    /// 背景图
    private let backgroundView: UIImageView = UIImageView()
    /// 边距约束
    var contentInset: UIEdgeInsets = .zero
    /// 图片与标题间隔
    var spacing: CGFloat = 3.0
    /// 布局方向
    var axis: NSLayoutConstraint.Axis = .horizontal
    /// 图片位置
    var imagePlacement: Placement = .leading
    /// 背景图片
    var backgroundImage: UIImage? {
        get { backgroundView.image }
        set { backgroundView.image = newValue }
    }
    /// 背景缩放方式
    override var contentMode: UIView.ContentMode {
        get { backgroundView.contentMode }
        set { backgroundView.contentMode = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundView.frame = bounds
        backgroundView.clipsToBounds = true
        backgroundView.contentMode = .scaleToFill
        backgroundView.isUserInteractionEnabled = false
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        
        titleLabel.isUserInteractionEnabled = false
        titleLabel.font = .systemFont(ofSize: 15.0, weight: .regular)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeToFit() {
        
        titleLabel.sizeToFit()
        titleLabel.width = ceil(titleLabel.width)
        titleLabel.height = ceil(titleLabel.height)
        
        // 以背景约束
        if (imageView.width <= 0.0 || imageView.height <= 0.0) && (titleLabel.width <= 0.0 || titleLabel.height <= 0.0) {
            if let image = backgroundView.image {
                var rect = frame
                if rect.width > 0.0 {
                    rect.size.height = ceil(image.size.height/image.size.width*rect.width)
                } else if rect.height > 0.0 {
                    rect.size.width = ceil(image.size.width/image.size.height*rect.height)
                }
                frame = rect
            }
            return
        }
        
        // 约束自身及图片, 标题
        if axis == .horizontal {
            // 横向布局
            let spacing = (titleLabel.width + imageView.width) > max(titleLabel.width, imageView.width) ? spacing : 0.0
            height = max(titleLabel.height, imageView.height) + contentInset.top + contentInset.bottom
            width = titleLabel.width + imageView.width + spacing + contentInset.left + contentInset.right
            titleLabel.midY = max(titleLabel.height, imageView.height)/2.0 + contentInset.top
            imageView.midY = titleLabel.midY
            if imagePlacement == .leading {
                // 图片在前
                imageView.minX = contentInset.left
                titleLabel.minX = imageView.maxX + spacing
            } else {
                // 标题在前
                titleLabel.minX = contentInset.left
                imageView.minX = titleLabel.maxX + spacing
            }
        } else {
            // 纵向布局
            let spacing = (titleLabel.height + imageView.height) > max(titleLabel.height, imageView.height) ? spacing : 0.0
            width = max(titleLabel.width, imageView.width) + contentInset.left + contentInset.right
            height = titleLabel.height + imageView.height + spacing + contentInset.top + contentInset.bottom
            titleLabel.midX = max(titleLabel.width, imageView.width)/2.0 + contentInset.left
            imageView.midX = titleLabel.midX
            if imagePlacement == .leading {
                // 图片在上
                imageView.minY = contentInset.top
                titleLabel.minY = imageView.maxY + spacing
            } else {
                // 标题在上
                titleLabel.minY = contentInset.top
                imageView.minY = titleLabel.maxY + spacing
            }
        }
    }
}
