//
//  MNToastComponents.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/8.
//  资源管理

import UIKit
import Foundation
import CoreGraphics

extension MNToast {
    @objc static func image(named name: String, type ext: String = "png") -> UIImage! {
        let imageName: String = name.contains("@") ? name : "\(name)@\(Int(UIScreen.main.scale))x"
        var path: String? = Bundle.toast.path(forResource: imageName, ofType: ext)
        if path == nil, name.contains("@") == false {
            var scale: Int = 3
            repeat {
                if let result = Bundle.toast.path(forResource: "\(name)@\(scale)x", ofType: ext) {
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
    static let toast: Bundle = {
        guard let path = Bundle(for: MNToast.self).path(forResource: "MNToast", ofType: "bundle") else { return .main }
        return Bundle(path: path)!
    }()
}
