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
            var rect: CGRect = bounds
            rect.size.width = max(contentSize.width, rect.width)
            if alignment == .left {
                imageView.autoresizingMask = []
                imageView.frame = rect
                imageView.autoresizingMask = [.flexibleRightMargin, .flexibleHeight]
            } else {
                rect.origin.x = frame.width - rect.width
                imageView.autoresizingMask = []
                imageView.frame = rect
                imageView.autoresizingMask = [.flexibleRightMargin, .flexibleHeight]
            }
        }
    }
    /// 图片
    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }
    /// 内容宽度
    var contentSize: CGSize {
        get { imageView.frame.size }
        set {
            let autoresizingMask = autoresizingMask
            var rect = imageView.frame
            rect.size = newValue
            imageView.frame = frame
            imageView.autoresizingMask = autoresizingMask
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.autoresizingMask = .flexibleHeight
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
