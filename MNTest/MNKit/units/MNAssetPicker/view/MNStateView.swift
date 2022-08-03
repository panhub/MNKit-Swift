//
//  MNStateView.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/2/7.
//  媒体资源缩略图-状态视图

import UIKit

class MNStateView: UIView {
    
    enum StateResizing: Int {
        case normal
        case highlighted
        case selected
    }
    
    private var s: StateResizing = .normal
    var state: StateResizing {
        get { s }
        set {
            guard s != newValue else { return }
            s = newValue
            for subview in subviews {
                subview.isHidden = subview.tag != newValue.rawValue
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        
        for state in [StateResizing.normal, StateResizing.highlighted, StateResizing.selected] {
            let imageView = UIImageView(frame: bounds)
            //imageView.backgroundColor = .yellow
            imageView.tag = state.rawValue
            imageView.isHidden = state != .normal
            imageView.contentMode = .scaleAspectFit
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(imageView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ image: UIImage?, for state: StateResizing) {
        guard let imageView = subviews[state.rawValue] as? UIImageView else { return }
        imageView.image = image
    }
}
