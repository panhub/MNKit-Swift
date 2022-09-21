//
//  MNAssetAlbum.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/27.
//  相簿模型

import UIKit
import Photos

class MNAssetAlbum: NSObject {
    /**
     相簿展示名称
     */
    var title: String?
    /**
     系统相簿
     */
    var collection: PHCollection!
    /**
     相簿缩略图
     */
    var thumbnail: UIImage!
    /**
     相簿检索结果
     */
    var result: PHFetchResult<PHAsset>?
    /**
     相簿资源集合
     */
    var assets: [MNAsset] = [MNAsset]()
    /**
     是否选中
     */
    var isSelected: Bool = false
    
    /**
     添加资源
     @param asset 资源模型
     */
    func add(asset: MNAsset) {
        objc_sync_enter(self)
        if assets.count <= 0 {
            assets.append(asset)
        } else {
            assets[assets.count - 1] = asset
        }
        thumbnail = assets.first!.thumbnail
        objc_sync_exit(self)
    }
    
    /**
     插入资源
     @param asset 资源模型
     */
    func insertAsset(atFront asset: MNAsset) {
        objc_sync_enter(self)
        if assets.count <= 0 {
            assets[0] = asset
        } else {
            assets[1] = asset
        }
        thumbnail = assets.first!.thumbnail
        objc_sync_exit(self)
    }
    
    /**
     删除所有资源
     */
    func removeAllAssets() {
        objc_sync_enter(self)
        assets.removeAll()
        objc_sync_exit(self)
    }
    
    /**
     删除指定资源
     @param assets 指定资源
     */
    func remove(assets: [MNAsset]) {
        objc_sync_enter(self)
        for asset in assets {
            if let index = self.assets.firstIndex(of: asset) {
                self.assets.remove(at: index)
            }
        }
        objc_sync_exit(self)
    }
    
    /**
     添加指定资源
     @param assets 指定资源
     */
    func add(assets: [MNAsset]) {
        objc_sync_enter(self)
        self.assets.append(contentsOf: assets)
        objc_sync_exit(self)
    }
    
    /**
     删除相册资源
     @param assets 指定资源
     */
    func remove(pHAssets: [PHAsset]) {
        objc_sync_enter(self)
        for phAsset in pHAssets {
            assets.removeAll { asset in
                guard let obj = asset.phAsset else { return false }
                return obj.localIdentifier == phAsset.localIdentifier
            }
        }
        objc_sync_exit(self)
    }
}
