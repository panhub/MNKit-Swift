//
//  UIImage+MNExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/15.
//  UIImage扩展

import UIKit
import Foundation
import QuartzCore
import CoreGraphics

extension UIImage {
    
    /// 灰度图片
    @objc var grayImage: UIImage? {
        guard let cgImage = cgImage else { return nil }
        let size: CGSize = CGSize(width: size.width*scale, height: size.height*scale)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        guard let newImage = context.makeImage() else { return nil }
        return UIImage(cgImage: newImage)
    }
    
    /**调整方向*/
    @objc var resizingOrientation: UIImage {
        
        guard imageOrientation != .up, let cgImage = cgImage, let colorSpace = cgImage.colorSpace else { return self }
        
        guard let context = CGContext.init(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else { return self }
        
        var transform: CGAffineTransform = .identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0.0)
            transform = transform.rotated(by: CGFloat(Double.pi/2.0))
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0.0, y: size.height)
            transform = transform.rotated(by: -CGFloat(Double.pi/2.0))
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        default:
            break
        }
    
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0.0, y: 0.0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        }
        
        guard let bitcgImage = context.makeImage() else { return self }
        
        return UIImage(cgImage: bitcgImage)
    }
    
    // MARK: - 裁剪部分图像
    @objc func crop(rect: CGRect) -> UIImage! {
        if rect == .zero { return self }
        guard let cgImage = cgImage?.cropping(to: CGRect(x: floor(rect.minX)*scale, y: floor(rect.minY)*scale, width: floor(rect.width)*scale, height: floor(rect.height)*scale)) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - 调整图片尺寸
    @objc func resizing(toMax pix: CGFloat) -> UIImage! {
        var size = CGSize(width: size.width*scale, height: size.height*scale)
        guard max(size.width, size.height) > pix else { return self }
        if size.width >= size.height {
            size.height = pix/size.width*size.height
            size.width = pix
        } else {
            size.width = pix/size.height*size.width
            size.height = pix
        }
        return resizing(toSize: size)
    }
    
    @objc func resizing(toSize size: CGSize) -> UIImage! {
        let targetSize = CGSize(width: floor(size.width), height: floor(size.height))
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        draw(in: CGRect(x: 0.0, y: 0.0, width: targetSize.width, height: targetSize.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    // 压缩至指定质量(约值) 失败则返回原图
    @objc func resizing(toQuality bytes: Int) -> UIImage {
        let min: CGFloat = 0.1
        let max: CGFloat = 0.9
        var data: Data?
        var last: CGFloat = max
        var quality: CGFloat = 0.6
        repeat {
            guard quality >= min, quality <= max else { break }
            guard let imageData = jpegData(compressionQuality: quality) else { break }
            data = imageData
            let count: Int = imageData.count
            guard fabs(Double(count - bytes)) > 1000.0 else { break }
            if count > bytes {
                last = quality
                quality = (quality - min)/2.0 + min
            } else {
                quality = (last - quality)/2.0 + quality
            }
        } while (true)
        guard let imageData = data else { return self }
        return UIImage(data: imageData) ?? self
    }
    
    @objc func renderBy(color: UIColor) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0.0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(.normal)
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        context?.clip(to: rect, mask: cgImage)
        color.setFill()
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /// 渲染纯色图片
    /// - Parameters:
    ///   - color: 颜色
    ///   - size: 尺寸
    @objc convenience init?(color: UIColor, size: CGSize = CGSize(width: 1.0, height: 1.0)) {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

extension UIImage {
    
    /// 将图片写入本地
    /// - Parameter filePath: 本地路径
    /// - Returns: 是否写入成功
    @objc func write(toFile filePath: String) -> Bool {
        let url = URL(fileURLWithPath: filePath)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch {
            #if DEBUG
            print(error)
            #endif
            return false
        }
        guard let imageData = Data(image: self) else { return false }
        do {
            try imageData.write(to: url)
        } catch {
            #if DEBUG
            print(error)
            #endif
            return false
        }
        return true
    }
}
