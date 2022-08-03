//
//  MNRefreshAutoFooter.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/24.
//  默认加载更多控件

import UIKit

class MNRefreshAutoFooter: MNRefreshFooter {
    // 修改颜色
    override var color: UIColor {
        get { super.color }
        set {
            super.color = newValue
            label.textColor = newValue
            indicatorView.color = newValue
        }
    }
    // 文字提示
    private lazy var label: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        label.textColor = color
        label.text = "暂无更多数据"
        label.sizeToFit()
        return label
    }()
    // 指示图
    private lazy var indicatorView: MNActivityIndicatorView = {
        let indicatorView = MNActivityIndicatorView(frame: CGRect(x: 0.0, y: 0.0, width: 18.0, height: 18.0))
        indicatorView.color = color
        indicatorView.lineWidth = 1.3
        return indicatorView
    }()
    
    override func initialized() {
        super.initialized()
        addSubview(label)
        addSubview(indicatorView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.midX = bounds.width/2.0
        indicatorView.midX = bounds.width/2.0
        if style == .margin {
            label.maxY = bounds.height - MN_TAB_SAFE_HEIGHT
            indicatorView.maxY = bounds.height - MN_TAB_SAFE_HEIGHT
        } else {
            label.midY = bounds.height/2.0
            indicatorView.midY = bounds.height/2.0
        }
    }
    
    override func refreshFooter(didChangePercent percent: CGFloat) {
        indicatorView.rotationAngle = CGFloat(Double.pi/180.0)*(360.0*percent)
    }
    
    override func refreshFooter(didChangeState old: MNRefresh.RefreshState, to: MNRefresh.RefreshState) {
        if to == .refreshing {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
        indicatorView.isHidden = to == .noMoreData
        label.isHidden = indicatorView.isHidden == false
    }
}
