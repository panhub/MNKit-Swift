//
//  MNRefreshNormalHeader.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/19.
//  默认下拉刷新控件

import UIKit

class MNRefreshNormalHeader: MNRefreshHeader {
    // 指示图层
    override var color: UIColor {
        get { super.color }
        set {
            super.color = newValue
            indicatorView.color = newValue
        }
    }
    private lazy var indicatorView: MNActivityIndicatorView = {
        let indicatorView = MNActivityIndicatorView(frame: CGRect(x: 0.0, y: 0.0, width: 18.0, height: 18.0))
        indicatorView.color = color
        indicatorView.lineWidth = 1.3
        return indicatorView
    }()
    
    override func initialized() {
        super.initialized()
        addSubview(indicatorView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
        if style == .margin {
            center.y =  (frame.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT
        }
        indicatorView.center = center
    }
    
    override func refreshHeader(didChangePercent percent: CGFloat) {
        indicatorView.rotationAngle = CGFloat(Double.pi/180.0)*(360.0*percent)
    }
    
    override func refreshHeader(didChangeState old: MNRefresh.RefreshState, to: MNRefresh.RefreshState) {
        if to == .refreshing {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
    }
}
