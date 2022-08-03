//
//  Data+MNImageFormat.swift
//  anhe
//
//  Created by 冯盼 on 2022/2/17.
//  获取图片格式

import UIKit
import Foundation

@objc enum MNImageFormat: Int {
    case undefined = -1
    case jpeg, png, gif, tiff, webp, heic
}

extension Data {
    
    /// 图片格式
    var imageFormat: MNImageFormat {
        let bytes = [UInt8](self)
        guard bytes.count > 0 else { return .undefined }
        switch bytes.first {
        case 0xFF:
            return .jpeg
        case 0x89:
            return .png
        case 0x47:
            return .gif
        case 0x49, 0x4D:
            return .tiff
        case 0x52:
            if count >= 12, let string = String(data: subdata(in: 0..<12), encoding: .ascii) {
                if string.hasPrefix("RIFF") || string.hasSuffix("WEBP") {
                    return .webp
                }
            }
        case 0x00:
            if count >= 12, let string = String(data: subdata(in: 4..<12), encoding: .ascii) {
                if string == "ftypheic" || string == "ftypheix" || string == "ftyphevc" || string == "ftyphevx" {
                    return .heic
                }
            }
        default:
            return .undefined
        }
        return .undefined
    }
    
    /// 获取图片格式
    /// - Parameter data: 图片数据流
    /// - Returns: 图片格式
    static func imageFormat(data: Data?) -> MNImageFormat {
        guard let imageData = data else { return .undefined }
        return imageData.imageFormat
    }
}

extension UIImage {
    
    /// 判断图片格式
    /// - Parameter imagePath: 图片路径
    /// - Returns: 图片格式
    func imageFormat(atPath imagePath: String) -> MNImageFormat {
        guard FileManager.default.fileExists(atPath: imagePath), let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else { return .undefined }
        return imageData.imageFormat
    }
}
