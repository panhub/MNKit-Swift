//
//  CGRect+MNExtension.swift
//  TLChat
//
//  Created by 冯盼 on 2022/8/2.
//

import UIKit
import Foundation
import CoreGraphics


extension CGRect {
    /// 九宫格布局
    /// - Parameters:
    ///   - offset: 横向/纵向偏移
    ///   - count: 数量
    ///   - column: 列数
    ///   - block: 回调
    func grid(offset: UIOffset, count: Int, column: Int, using block: (Int, CGRect,  UnsafeMutablePointer<Bool>)->Void) {
        guard count > 0, column > 0 else { return }
        let x = minX
        let y = minY
        let w = width
        let h = height
        let xm = offset.horizontal
        let ym = offset.vertical
        var stop: Bool = false
        for idx in 0..<count {
            let minX: CGFloat = x + (w + xm)*CGFloat((idx%column))
            let minY: CGFloat = y + (h + ym)*CGFloat((idx/column))
            let rect = CGRect(x: minX, y: minY, width: w, height: h)
            block(idx, rect, &stop)
            if stop { break }
        }
    }
}
