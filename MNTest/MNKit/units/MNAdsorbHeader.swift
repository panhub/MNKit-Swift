//
//  MNAdsorbView.swift
//  anhe
//
//  Created by 冯盼 on 2022/6/14.
//  吸附效果

import UIKit

class MNAdsorbHeader: UIView {
    /// 内容视图 避免触发"layoutSubviews"
    let contentView: UIView = UIView()
    /// 图片显示
    let imageView: UIImageView = UIImageView()
    /// 记录父视图
    private(set) weak var scrollView: UIScrollView?
    /// 记录图片原始位置
    private var imageViewY: CGFloat = 0.0
    /// 监听的key
    private let observeKeyPath: String = "contentOffset"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        imageView.frame = contentView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let scrollView = superview as? UIScrollView else { return }
        self.scrollView = scrollView
        imageView.autoresizingMask = []
        imageViewY = imageView.frame.maxY
        scrollView.alwaysBounceVertical = true
        scrollView.addObserver(self, forKeyPath: observeKeyPath, options: .new, context: nil)
    }
    
    override func removeFromSuperview() {
        if let scrollView = superview as? UIScrollView {
            self.scrollView = nil
            scrollView.removeObserver(self, forKeyPath: observeKeyPath)
        }
        super.removeFromSuperview()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, keyPath == observeKeyPath, let scrollView = object as? UIScrollView else { return }
        guard let new = change?[.newKey] as? CGPoint else { return }
        let offsetY: CGFloat = new.y
        let top: CGFloat = scrollView.contentInset.top
        guard offsetY <= -top else { return }
        var frame = contentView.frame
        frame.size.height = imageViewY - offsetY
        frame.origin.y = imageViewY - frame.height
        imageView.frame = frame
    }
}
