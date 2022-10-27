//
//  MNProgressView.swift
//  MNTest
//
//  Created by 冯盼 on 2022/10/27.
//  网页进度条

import UIKit

class MNProgressView: UIProgressView {
    /// 进度满时消失
    var fadeWhenFull: Bool = true
    /// 消失延迟
    var fadeAnimationDelay: TimeInterval = 0.5
    /// 消失动画时长
    var fadeAnimationDuration: TimeInterval = 0.25
    /// 定义最小的透明度
    private let leastAlphaMagnitude: CGFloat = 0.0001
    
    override var progress: Float {
        get { super.progress }
        set {
            super.progress = newValue
            startFadeAnimation()
        }
    }
    
    override func setProgress(_ progress: Float, animated: Bool) {
        super.setProgress(progress, animated: animated)
        startFadeAnimation()
    }
    
    /// 开始检测是否需要隐藏
    private func startFadeAnimation() {
        guard fadeWhenFull else { return }
        let progress = progress
        let subviews = subviews
        let leastAlphaMagnitude = leastAlphaMagnitude
        let alpha: CGFloat = subviews.reduce(0.0) { max($0, $1.alpha) }
        if progress >= 1.0, alpha > leastAlphaMagnitude {
            // 需要隐藏
            UIView.animate(withDuration: fadeAnimationDuration, delay: max(0.1, fadeAnimationDelay), options: [.beginFromCurrentState, .curveEaseInOut]) {
                for subview in subviews {
                    subview.alpha = leastAlphaMagnitude
                }
            } completion: { _ in
                // 如果仍处于隐藏状态就恢复初始值
                let alpha: CGFloat = subviews.reduce(0.0) { max($0, $1.alpha) }
                if alpha <= leastAlphaMagnitude {
                    super.progress = 0.0
                }
            }
        } else if progress < 1.0, alpha <= leastAlphaMagnitude {
            // 需要显示
            UIView.animate(withDuration: fadeAnimationDuration, delay: .leastNormalMagnitude, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                for subview in subviews {
                    subview.alpha = 1.0
                }
            }, completion: nil)
        }
    }
}
