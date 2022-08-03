//
//  QRCode.swift
//  anhe
//
//  Created by 冯盼 on 2022/3/30.
//  二维码

import UIKit
import Foundation
import CoreImage
import CoreGraphics

class QRCode {
    
    private(set) var image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
    
    convenience init?(data metadata: Data, pixel: Int) {
        guard pixel > 0 else { return nil }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator", parameters: nil) else { return nil }
        filter.setDefaults()
        filter.setValue(metadata, forKey: "inputMessage")
        guard let outputImage = filter.outputImage else { return nil }
        
        let extent = outputImage.extent.integral
        guard let context = CGContext(data: nil, width: pixel, height: pixel, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        guard let cgimage = CIContext().createCGImage(outputImage, from: extent) else { return nil }
        context.interpolationQuality = .none
        context.scaleBy(x: CGFloat(pixel)/extent.width, y: CGFloat(pixel)/extent.height)
        context.draw(cgimage, in: extent)
        guard let cgImage = context.makeImage() else { return nil }
        self.init(image: UIImage(cgImage: cgImage))
    }
}
