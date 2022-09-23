//
//  UIImage+MNAssetExport.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/29.
//  对图片输出处理

import UIKit
import Photos
import Foundation
import CoreGraphics

// MARK: - 图片处理
extension UIImage {
    
    
    /// 近似微信朋友圈图片压缩 (以1280为界以 0.6为压缩系数)
    /// - Parameters:
    ///   - pixel: 像素阀值
    ///   - quality: 压缩系数
    /// - Returns: (压缩后图片, 图片质量)
    func compress(pixel: CGFloat = 1280.0, quality: CGFloat) -> (UIImage?, Int) {
        guard pixel > 0.0, quality > 0.01 else { return (nil, 0) }
        // 调整尺寸
        var width: CGFloat = size.width*scale
        var height: CGFloat = size.height*scale
        guard width > 0.0, height > 0.0 else { return (nil, 0) }
        let boundary: CGFloat = pixel
        let isSquare: Bool = width == height
        if width > boundary || height > boundary {
            if max(width, height)/min(width, height) <= 2.0 {
                let ratio: CGFloat = boundary/max(width, height)
                if width >= height {
                    width = boundary
                    height = height*ratio
                } else {
                    height = boundary
                    width = width*ratio
                }
            } else if min(width, height) > boundary {
                let ratio: CGFloat = boundary/min(width, height)
                if width <= height {
                    width = boundary
                    height = height*ratio
                } else {
                    height = boundary
                    width = width*ratio
                }
            }
            width = ceil(width)
            height = ceil(height)
            if isSquare {
                width = min(width, height)
                height = width
            }
        }
        // 缩图片
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        draw(in: CGRect(x: 0.0, y: 0.0, width: width, height: height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // 压图片
        if let imageData = result?.jpegData(compressionQuality: quality), let image = UIImage(data: imageData) {
            return (image, imageData.count)
        }
        return (nil, 0)
    }
    
    /**近似微信朋友圈图片压缩(以1280为界以0.6为压缩系数)*/
    @objc func optimized(compressionQuality quality: CGFloat) -> UIImage {
        return compress(pixel: 1280, quality: quality).0 ?? self
    }
}

// MARK: - 寻找合适的加载控制器
extension MNAssetPicker {
    @objc static var present: UIViewController? {
        var viewController = UIApplication.shared.delegate?.window??.rootViewController
        repeat {
            guard let _ = viewController else { break }
            if let vc = viewController!.presentedViewController {
                viewController = vc
            } else if (viewController! is UINavigationController) {
                viewController = (viewController! as! UINavigationController).viewControllers.last
            } else if (viewController! is UITabBarController) {
                viewController = (viewController! as! UITabBarController).selectedViewController
            } else { break }
        } while (viewController != nil)
        return viewController
    }
}

// MARK: - 资源文件获取
extension MNAssetPicker {
    static func image(named name: String, type ext: String = "png") -> UIImage? {
        let imageName: String = name.contains("@") ? name : "\(name)@\(Int(UIScreen.main.scale))x"
        var path: String? = Bundle.picker.path(forResource: imageName, ofType: ext)
        if path == nil, name.contains("@") == false {
            var scale: Int = 3
            repeat {
                if let result = Bundle.picker.path(forResource: "\(name)@\(scale)x", ofType: ext) {
                    path = result
                    break
                }
                scale -= 1
            } while (scale > 0)
        }
        guard let imagePath = path else { return nil }
        return UIImage(contentsOfFile: imagePath)
    }
}

fileprivate extension Bundle {
    static let picker: Bundle = {
        guard let path = Bundle(for: MNAssetPicker.self).path(forResource: "MNAssetPicker", ofType: "bundle") else { return .main }
        return Bundle(path: path)!
    }()
}

// MARK: - 计算适应尺寸
extension CGSize {
    func scaleAspectFit(toSize target: CGSize) -> CGSize {
        let size = CGSize(width: floor(target.width), height: floor(target.height))
        guard min(size.width, size.height) > 0.0, min(self.width, self.height) > 0.0 else { return size }
        var width = 0.0
        var height = 0.0
        if size.height >= size.width {
            // 竖屏/方形
            width = size.width
            height = self.height/self.width*width
            if height.isNaN || height < 1.0 {
                height = 1.0
            } else if height == size.height {
                height = max(0.0, size.height - 1.0)
            } else if height > size.height {
                height = max(0.0, size.height - 1.0)
                width = self.width/self.height*height
                if (width.isNaN || width < 1.0) { width = 1.0 }
                width = floor(width)
            } else {
                height = floor(height)
            }
        } else {
            // 横屏
            height = max(0.0, size.height - 1.0)
            width = self.width/self.height*height
            if width.isNaN || width < 1.0 {
                width = 1.0
            } else if width > size.width {
                width = size.width
                height = self.height/self.width*width
                if height.isNaN || height < 1.0 { height = 1.0 }
                height = floor(height)
            } else {
                width = floor(width)
            }
        }
        return CGSize(width: width, height: height)
    }
}

// MARK: - 计算文件大小
extension Int64 {
    /// 文件大小字符串形式 (G精确两位小数, M精确一位, KB取整)
    var fileSizeValue: String {
        /// 规范化文件大小字符串
        func validDecimalNumber(_ number: NSDecimalNumber) -> String {
            let other = NSDecimalNumber(value: number.intValue)
            if number == other { return other.stringValue }
            return number.stringValue
        }
        // Apple 采取1000作为储存进制
        guard self > 0 else { return "0K" }
        let number: NSDecimalNumber = NSDecimalNumber(value: self)
        if self >= 1000*1000*1000 {
            let dividend: NSDecimalNumber = NSDecimalNumber(value: 1000*1000*1000)
            let behavior: NSDecimalNumberHandler = NSDecimalNumberHandler(roundingMode: .plain, scale: 2, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            let result: NSDecimalNumber = number.dividing(by: dividend, withBehavior: behavior)
            guard result.decimalValue.isNaN == false else { return "0K" }
            return validDecimalNumber(result) + "G"
        } else if self >= 1000*1000 {
            let dividend: NSDecimalNumber = NSDecimalNumber(value: 1000*1000)
            let behavior: NSDecimalNumberHandler = NSDecimalNumberHandler(roundingMode: .plain, scale: 1, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            let result: NSDecimalNumber = number.dividing(by: dividend, withBehavior: behavior)
            guard result.decimalValue.isNaN == false else { return "0K" }
            return validDecimalNumber(result) + "M"
        } else if self >= 1000 {
            let dividend: NSDecimalNumber = NSDecimalNumber(value: 1000)
            let behavior: NSDecimalNumberHandler = NSDecimalNumberHandler(roundingMode: .up, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            let result: NSDecimalNumber = number.dividing(by: dividend, withBehavior: behavior)
            guard result.decimalValue.isNaN == false else { return "0K" }
            return "\(result.intValue)K"
        }
        return "\(self)B"
    }
}
extension Int {
    var fileSizeValue: String { Int64(self).fileSizeValue }
}
