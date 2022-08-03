//
//  UIImage+MNAnimated.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/27.
//  动态图

import UIKit
import Foundation
import ImageIO.ImageIOBase
import CoreServices.UTCoreTypes

extension UIImage {
    
    // MARK: - 是否是动态图
    @objc var isAnimatedImage: Bool {
        return NSStringFromClass(Self.self).contains("UIAnimatedImage")
    }
    
    // MARK: - 转换图片至数据流
    @objc var gifData: Data? {
        return Data.data(image: self)
    }
    
    // MARK: - 依据情况实例化动图
    @objc static func image(contentsAtFile filePath: String?) -> UIImage? {
        guard let path = filePath, FileManager.default.fileExists(atPath: path) else { return nil }
        return image(contentsOfData: try? Data(contentsOf: URL(fileURLWithPath: path)))
    }
    
    @objc static func image(contentsOfData data: Data?) -> UIImage? {
        guard let imageData = data, imageData.count > 0  else { return nil }
        let options: [CFString: Any] = [kCGImageSourceShouldCache:kCFBooleanTrue!, kCGImageSourceTypeIdentifierHint:kUTTypeGIF]
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, options as CFDictionary) else { return nil }
        let count = CGImageSourceGetCount(imageSource)
        guard count > 0 else { return nil }
        if count == 1 { return UIImage(data: imageData) }
        // 时长
        var duration: TimeInterval = 0.0
        var images: [UIImage] = [UIImage]()
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, options as CFDictionary) else { continue }
            let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
            guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, options as CFDictionary) else { continue }
            let key = Unmanaged.passRetained(kCGImagePropertyGIFDictionary as NSString).autorelease().toOpaque()
            guard let value = CFDictionaryGetValue(properties, key) else { continue }
            let dic = Unmanaged<NSDictionary>.fromOpaque(value).takeUnretainedValue()
            guard let gifProperties = dic as? [CFString:Any] else { continue }
            let interval: TimeInterval? = (gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval) ?? (gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval)
            guard let delay = interval else { continue }
            duration += max(delay, 0.1)
            images.append(image)
        }
        // 生成动态图
        guard images.count > 0 else { return UIImage(data: imageData) }
        if images.count == 1 { return images.first }
        return UIImage.animatedImage(with: images, duration: duration)
    }
}

// MARK: - 获取图片数据流
extension Data {
    
    /// UIImage -> Data
    /// - Parameters:
    ///   - conImage: 待转化的图片
    ///   - quality: 压缩质量
    /// - Returns: Data或nil
    static func data(image conImage: UIImage?, compression quality: CGFloat = 0.65) -> Data? {
        guard let image = conImage else { return nil }
        guard let images = image.images, images.count > 1, image.duration > 0.0, image.isAnimatedImage else {
            guard let jpegData = image.jpegData(compressionQuality: quality) else { return image.pngData() }
            return jpegData
        }
        // GIF
        let count = images.count
        let delay: TimeInterval = image.duration/TimeInterval(count)
        let frameProperties: [CFString:[CFString:Any]] = [kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFDelayTime :delay]]
        let gifData: NSMutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(gifData as CFMutableData, kUTTypeGIF, count, nil) else { return nil }
        let imageProperties: [CFString:[CFString:Any]] = [kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFLoopCount:0]]
        CGImageDestinationSetProperties(destination, imageProperties as CFDictionary)
        for index in 0..<count {
            guard let cgImage = images[index].cgImage else { continue }
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { return nil }
        let imageData = gifData as Data
        guard imageData.count > 0 else { return nil }
        return imageData
    }
}
