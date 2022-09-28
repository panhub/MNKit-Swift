//
//  UILabel+MNExtension.swift
//  anhe
//
//  Created by 冯盼 on 2022/2/14.
//

import UIKit
import Foundation

extension UILabel {
    
    public override func sizeFitToWidth() {
        if let attributedText = attributedText {
            // 富文本
            var frame = frame
            let size = attributedText.boundingRect(with: CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).size
            frame.size.height = size.height
            self.frame = frame
        } else if let text = text {
            // 文字
            let font = font ?? .systemFont(ofSize: 17.0, weight: .regular)
            var frame = frame
            let size = NSAttributedString(string: text, attributes: [.font:font]).boundingRect(with: CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).size
            frame.size.height = size.height
            self.frame = frame
        }
    }
    
    public override func sizeFitToHeight() {
        if let attributedText = attributedText {
            // 富文本
            var frame = frame
            let size = attributedText.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: frame.size.height), options: .usesLineFragmentOrigin, context: nil).size
            frame.size.width = size.width
            self.frame = frame
        } else if let text = text {
            // 文字
            let font = font ?? .systemFont(ofSize: 17.0, weight: .regular)
            var frame = frame
            let size = NSAttributedString(string: text, attributes: [.font:font]).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: frame.size.height), options: .usesLineFragmentOrigin, context: nil).size
            frame.size.width = size.width
            self.frame = frame
        }
    }
}
