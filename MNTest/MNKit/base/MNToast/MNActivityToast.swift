//
//  MNActivityToast.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/10.
//  Indicator弹窗

import UIKit

class MNActivityToast: MNToast {
    
    private var indicator: UIActivityIndicatorView!
    
    override func createView() {
        super.createView()
        
        var style: UIActivityIndicatorView.Style
        if #available(iOS 13.0, *) {
            style = .large
        } else {
            style = .whiteLarge
        }
        let indicator = UIActivityIndicatorView(style: style)
        indicator.color = Self.color
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        container.frame = indicator.frame
        container.addSubview(indicator)
        self.indicator = indicator
    }
    
    override func removeFromSuperview() {
        indicator?.stopAnimating()
        super.removeFromSuperview()
    }
}
