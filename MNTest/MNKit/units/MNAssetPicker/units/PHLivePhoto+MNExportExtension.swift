//
//  PHLivePhoto+MNExportExtension.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/20.
//

import Foundation
import Photos
import ObjectiveC.runtime

public typealias MNLivePhotoResourceKey = String
public let MNLivePhotoVideoUrlKey: MNLivePhotoResourceKey  = "com.mn.live.photo.video.url"
public let MNLivePhotoImageUrlKey: MNLivePhotoResourceKey  = "com.mn.live.photo.image.url"

@available(iOS 9.1, *)
public extension PHLivePhoto {
    private struct AssociatedKey {
        static var videoResource = "com.mn.live.photo.video.url"
        static var imageResource = "com.mn.live.photo.image.url"
    }
    
    @objc var videoFileURL: URL? {
        get { objc_getAssociatedObject(self, &AssociatedKey.videoResource) as? URL}
        set { objc_setAssociatedObject(self, &AssociatedKey.videoResource, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    @objc var imageFileURL: URL? {
        get { objc_getAssociatedObject(self, &AssociatedKey.imageResource) as? URL}
        set { objc_setAssociatedObject(self, &AssociatedKey.imageResource, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
}

// LivePhoto导出辅助
@available(iOS 9.1, *)
class PHLivePhotoBuffer {
    var data = Data()
    var type: PHAssetResourceType = .photo
}

