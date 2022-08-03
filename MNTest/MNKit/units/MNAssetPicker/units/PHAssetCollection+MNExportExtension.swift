//
//  PHAssetCollection+MNExportExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/30.
//

import Photos
import Foundation

extension PHAssetCollection {
    /**是否是相机资源集合*/
    @objc var isCameraCollection: Bool {
        guard assetCollectionType == .smartAlbum else { return false }
        let subtype: PHAssetCollectionSubtype = (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0 && NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_8_2) ? .smartAlbumRecentlyAdded : .smartAlbumUserLibrary
        return assetCollectionSubtype == subtype
    }
}
