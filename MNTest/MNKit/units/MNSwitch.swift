//
//  MNSwitch.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/28.
//

import UIKit

class MNSwitch: UIView {
    
    let s = UISwitch()
    
    private let spacing: CGFloat = 2.0
    
    private let thumb = UIView()
    
    @objc var isOn: Bool { thumb.center.x > bounds.midX }
    
    override init(frame: CGRect) {
        var rect: CGRect = frame
        if max(frame.width, frame.height) <= 0.0 {
            rect.size = CGSize(width: 40.0, height: 20.0)
        }
        if floor(rect.width) <= ceil(rect.height) {
            fatalError("MNSwitch size not available: \(frame.size)")
        }
        super.init(frame: rect)
        
        UIStackView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
