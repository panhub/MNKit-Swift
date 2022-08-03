//
//  MNProgressView.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/7.
//  网页加载进度

import UIKit

public class MNWebProgressView: UIView {
    /**进度*/
    private var _progress: Double = 0.0
    public var progress: Double {
        get { _progress }
        set { set(progress: newValue, animated: false) }
    }
    /**进度视图*/
    private var progressView: UIView!
    /**消失延迟*/
    public var fadeOutDelay: TimeInterval = 0.5
    /**消失/出现动画间隔*/
    public var fadeAnimationDuration: TimeInterval = 0.25
    /**进度动画间隔*/
    public var progressAnimationDuration: TimeInterval = 0.25
    /**进度颜色*/
    public override var tintColor: UIColor! {
        get { progressView.backgroundColor }
        set { progressView.backgroundColor = newValue }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = UIColor.clear
        // 内容视图
        let contentView = UIView(frame: bounds)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        // 进度
        progressView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: frame.height))
        progressView.alpha = 0.0
        progressView.autoresizingMask = .flexibleHeight
        progressView.backgroundColor = UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 254.0/255.0, alpha: 1.0)
        contentView.addSubview(progressView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**更新进度*/
    public override func layoutSubviews() {
        set(progress: progress, animated: false)
    }
    
    /**设置进度*/
    public func set(progress: Double, animated: Bool) -> Void {
        _progress = max(min(1.0, progress), 0.0)
        self.progressView.layer.removeAllAnimations()
        // 更新位置
        UIView.animate(withDuration: ((self.progress > 0.0 && animated) ? self.progressAnimationDuration : 0.0), delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            var frame = self.progressView.frame
            frame.size.width = self.bounds.width*CGFloat(self.progress)
            self.progressView.frame = frame
        }, completion: nil)
        // 更新Alpha
        if self.progress >= 1.0, self.progressView.alpha != 0.0 {
            // 隐藏进度图
            UIView.animate(withDuration: (animated ? self.fadeAnimationDuration : 0.0), delay: (animated ? self.fadeOutDelay : 0.0), options: .curveEaseInOut) { [weak self] in
                guard let self = self else { return }
                self.progressView.alpha = 0.0
            } completion: { [weak self] finish in
                guard let self = self else { return }
                if finish {
                    // 刷新视图位置
                    var frame = self.progressView.frame
                    frame.size.width = 0.0
                    self.progressView.frame = frame
                }
            }
        } else if self.progress < 1.0, self.progressView.alpha != 1.0 {
            // 显示进度图
            UIView.animate(withDuration: (animated ? self.fadeAnimationDuration : 0.0), delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self = self else { return }
                self.progressView.alpha = 1.0
            }, completion: nil)
        }
    }
}
