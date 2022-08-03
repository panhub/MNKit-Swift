//
//  UIButton+Category.swift
//  anhe
//
//  Created by chaowen deng on 2022/2/8.
//

import Foundation
import UIKit

extension UIButton {
    
    convenience init(frame: CGRect, title: String?, font: UIFont = .systemFont(ofSize: 17.0), image background: UIImage? = nil) {
        self.init(type: .custom)
        self.frame = frame
        titleLabel?.font = font
        setTitle(title, for: .normal)
        setBackgroundImage(background, for: .normal)
        contentVerticalAlignment = .center
        contentHorizontalAlignment = .center
    }
}


