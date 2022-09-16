//
//  PHAsset+MNExportExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/30.
//

import Photos
import Foundation

extension PHAsset {
    
    var pixelSize: CGSize {
        CGSize(width: pixelWidth, height: pixelHeight)
    }
    
    var isGif: Bool {
        if #available(iOS 9.0, *) {
            for resource in PHAssetResource.assetResources(for: self) {
                let uti = resource.uniformTypeIdentifier.lowercased()
                if uti.contains("gif") { return true }
            }
            return false
        } else {
            let uti = (value(forKey: "uniformTypeIdentifier") as? String) ?? ""
            return uti.contains("gif")
        }
    }
    
    var isMov: Bool {
        if #available(iOS 9.0, *) {
            for resource in PHAssetResource.assetResources(for: self) {
                let uti = resource.uniformTypeIdentifier.lowercased()
                if uti.contains("mov") { return true }
            }
            return false
        } else {
            let uti = (value(forKey: "uniformTypeIdentifier") as? String) ?? ""
            return uti.contains("mov")
        }
    }
    
    var isHeifc: Bool {
        if #available(iOS 9.0, *) {
            for resource in PHAssetResource.assetResources(for: self) {
                let uti = resource.uniformTypeIdentifier.lowercased()
                if uti.contains("heif") || uti.contains("heic") { return true }
            }
            return false
        } else {
            let uti = (value(forKey: "uniformTypeIdentifier") as? String) ?? ""
            return (uti.contains("heif") || uti.contains("heic"))
        }
    }
    
    var filename: String? {
        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if resources.count > 0 {
                return resources.first!.originalFilename
            }
        }
        return nil
    }
    
    @available(iOS 9.1, *)
    var liveImageFilename: String? {
        for resource in PHAssetResource.assetResources(for: self) {
            let filename = resource.originalFilename
            let lowercased = filename.lowercased()
            if lowercased.contains("jpg") || lowercased.contains("jpeg") {
                return filename
            }
        }
        return nil
    }
    
    @available(iOS 9.1, *)
    var liveVideoFilename: String? {
        for resource in PHAssetResource.assetResources(for: self) {
            let filename = resource.originalFilename
            if filename.lowercased().contains("mov") {
                return filename
            }
        }
        return nil
    }
}
