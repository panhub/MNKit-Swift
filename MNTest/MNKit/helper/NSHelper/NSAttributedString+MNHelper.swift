//
//  NSAttributedString+MNHelper.swift
//  tiescreen
//
//  Created by 冯盼 on 2022/7/4.
//

import UIKit
import Foundation
import CoreGraphics

extension NSAttributedString {
    
    /// 自身范围
    var rangeOfAll: NSRange { NSRange(location: 0, length: length) }
    
    /// 富文本尺寸
    /// - Parameter width: 最大宽度
    /// - Returns: 尺寸
    func size(width: CGFloat) -> CGSize {
        boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size
    }
    
    /// 富文本尺寸
    /// - Parameter height: 最大高度
    /// - Returns: 尺寸
    func size(height: CGFloat) -> CGSize {
        boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: height), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size
    }
}

extension NSAttributedString {
    
    /// 初始化附件富文本
    /// - Parameters:
    ///   - image: 图片
    ///   - font: 文字大小
    ///   - spacing: 调整
    convenience init(image: UIImage!, font: UIFont, resizing spacing: CGFloat = 0.0) {
        let attachment = NSTextAttachment()
        attachment.image = image
        //attachment.image = UIImage(cgImage: image.cgImage!, scale: UIScreen.main.scale, orientation: .up)
        attachment.bounds = CGRect(x: 0.0, y: font.descender, width: font.lineHeight + spacing*2.0, height: font.lineHeight + spacing*2.0)
        self.init(attachment: attachment)
    }
}
