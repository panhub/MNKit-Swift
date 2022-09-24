//
//  MNVideoKeyfram.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/23.
//  视频关键帧集合视图

import UIKit

class MNVideoKeyfram: UIView {
    
    enum Alignment {
        case left, right
    }
    
    /// 内部显示视图
    private let imageView: UIImageView = UIImageView()
    /// 对齐方式
    var alignment: Alignment = .left {
        didSet {
            setNeedsLayout()
        }
    }
    /// 内容尺寸
    var contentSize: CGSize {
        get { imageView.frame.size }
        set {
            var rect = bounds
            rect.size.width = max(rect.width, newValue.width)
            imageView.frame = rect
            setNeedsLayout()
        }
    }
    /// 图片
    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        guard alignment == .right else { return }
        imageView.maxX = bounds.width
    }
}
