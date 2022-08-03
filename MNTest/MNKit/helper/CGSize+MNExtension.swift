//
//  CGSize+MNExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/22.
//

import Foundation
import CoreGraphics

extension CGSize {
    
    var isEmpty: Bool {
        return (width.isNaN || height.isNaN || width <= 0.0 || height <= 0.0)
    }
    
    func multiplyTo(width: CGFloat) -> CGSize {
        guard self.isEmpty == false else { return .zero }
        return CGSize(width: width, height: width/self.width*height)
    }
    
    func multiplyTo(height: CGFloat) -> CGSize {
        guard isEmpty == false else { return .zero }
        return CGSize(width: height/self.height*width, height: height)
    }
    
    func multiplyTo(min: CGFloat) -> CGSize {
        guard isEmpty == false else { return .zero }
        return width <= height ? multiplyTo(width: min) : multiplyTo(height: min)
    }
    
    func multiplyTo(max: CGFloat) -> CGSize {
        guard isEmpty == false else { return .zero }
        return width >= height ? multiplyTo(width: max) : multiplyTo(height: max)
    }
}
