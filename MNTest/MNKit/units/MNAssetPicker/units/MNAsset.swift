//
//  MNAsset.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/27.
//  相册资源模型

import UIKit
import Photos
import Foundation
import AVFoundation.AVAsset

/**
 数据改变回调
 */
typealias MNAssetUpdateHandler = (MNAsset)->Void

class MNAsset: NSObject {
    /**
     资源类型
     - photo: 图片
     - video: 视频
     - livePhoto: LivePhoto
     - gif: 动态图
     */
    @objc enum AssetType: Int {
        case photo, gif, livePhoto, video
    }
    /**
     文件来源
     - unknown: 未知
     - cloud: iCloud
     - local: 本地
     */
    @objc enum AssetSource: Int {
        case unknown, local, cloud
    }
    /**
     本地标识
     */
    @objc var identifier: String = ""
    /**
     文件类型
     */
    @objc var type: AssetType = .photo
    /**
     资源来源
     */
    @objc var source: AssetSource = .unknown
    /**
     图片: 调整后的图片
     视频: 路径
     LivePhoto : PHLivePhoto
     */
    @objc var content: Any?
    /**
     显示大小
     */
    @objc var renderSize: CGSize = CGSize(width: 250.0, height: 250.0)
    /**
     时长(仅视频资源有效)
     */
    @objc var duration: TimeInterval = 0.0
    /**
     时长(duration的字符串表现形式)
     */
    @objc lazy var durationValue: String = {
        return Date(timeIntervalSince1970: ceil(duration)).timeValue
    }()
    /**
     文件大小
     */
    @objc var fileSize: Int64 = 0
    /**
     文件大小字符串
     */
    @objc lazy var fileSizeValue: String = {
        guard fileSize > 0 else { return "" }
        return fileSize.fileSizeValue
    }()
    /**
     缩略图
     */
    @objc var thumbnail: UIImage?
    /**
     是否选中
     */
    @objc var isSelected: Bool = false
    /**
     是否是有效资源
     */
    @objc var isEnabled: Bool = true
    /**
     记录系统资源项, 与'PHPhoto'交互时使用
     */
    @objc var phAsset: PHAsset?
    /**
     PHImageRequestID, 缩略图请求id
     */
    @objc var requestId: Int32 = PHInvalidImageRequestID
    /**
     PHImageRequestID, 内容下载id
     */
    @objc var downloadId: Int32 = PHInvalidImageRequestID
    /**
     下载进度
     */
    @objc var progress: Double = 0.0
    /**
     选择索引
     */
    @objc var index: Int = 0
    /**
     标记展示它的View(预览时使用)
     */
    @objc weak var container: UIView?
    /**
     缩略图回调
     */
    @objc var thumbnailUpdateHandler: MNAssetUpdateHandler?
    /**
     资源来源发生变化回调
     */
    @objc var sourceUpdateHandler: MNAssetUpdateHandler?
    /**
     文件大小变化回调
     */
    @objc var fileSizeUpdateHandler: MNAssetUpdateHandler?
    
    /**
     取消内容请求
     */
    @objc func cancelRequest() {
        MNAssetHelper.cancel(request: self)
    }
    
    /**
     取消内容下载请求
     */
    @objc func cancelDownload() {
        MNAssetHelper.cancel(download: self)
    }
    
    /**
     修改缩略图
     @param thumbnail 缩略图
     */
    @objc func update(thumbnail: UIImage?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.thumbnail = thumbnail
            self.thumbnailUpdateHandler?(self)
        }
    }
    
    /**
     修改来源
     @param source 来源
     */
    @objc func update(source: AssetSource) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.source = source
            self.sourceUpdateHandler?(self)
        }
    }
    
    /**
     修改文件大小
     @param fileSize 文件大小
     */
    @objc func update(fileSize: Int64) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.fileSize = fileSize
            self.fileSizeUpdateHandler?(self)
        }
    }
    
    /**
     释放时处理
     */
    deinit {
        content = nil
        thumbnailUpdateHandler = nil
        sourceUpdateHandler = nil
        fileSizeUpdateHandler = nil
        cancelRequest()
        cancelDownload()
    }
    
    convenience init?(content: Any, options: MNAssetPickerOptions? = nil) {
        self.init()
        isEnabled = true
        source = .local
        if let _ = options { renderSize = options!.renderSize }
        var filePath: String!
        if content is UIImage, let image = content as? UIImage {
            // 图片
            if let images = image.images, images.count > 1 {
                type = .gif
                thumbnail = images.first!.resizing(toMax: max(renderSize.width, renderSize.height))
            } else {
                type = .photo
                thumbnail = image.resizing(toMax: max(renderSize.width, renderSize.height))
            }
            self.content = image
        } else if content is String {
            filePath = content as? String
        } else if content is URL, let url = content as? URL, url.isFileURL {
            filePath = url.path
        }
        if let _ = filePath, FileManager.default.fileExists(atPath: filePath) {
            type = .video
            duration = MNAssetExporter.duration(mediaAtPath: filePath)
            thumbnail = MNAssetExporter.thumbnail(videoAtPath: filePath)
            //durationString = Date(timeIntervalSince1970: ceil(duration)).timeValue
            if let _ = options, options!.isShowFileSize, let attributes = try? FileManager.default.attributesOfItem(atPath: filePath), let fileSize = (attributes[FileAttributeKey.size] as? NSNumber)?.int64Value {
                self.fileSize = fileSize
            }
            self.content = filePath
        } else if #available(iOS 9.1, *) {
            if content is PHLivePhoto, let livePhoto = content as? PHLivePhoto, let videoURL = livePhoto.videoFileURL, let imageURL = livePhoto.imageFileURL {
                type = .livePhoto
                thumbnail = UIImage(contentsOfFile: imageURL.path)?.resizing(toMax: max(renderSize.width, renderSize.height))
                if let _ = options, options!.isShowFileSize {
                    var fileSize: Int64 = 0
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: imageURL.path), let imageFileSize = (attributes[FileAttributeKey.size] as? NSNumber)?.int64Value {
                        fileSize += imageFileSize
                    }
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: videoURL.path), let videoFileSize = (attributes[FileAttributeKey.size] as? NSNumber)?.int64Value {
                        fileSize += videoFileSize
                    }
                    self.fileSize = fileSize
                }
                self.content = livePhoto
            }
        }
        guard let _ = self.content else { return nil }
        fileSizeValue = fileSize.fileSizeValue
    }
}

// MARK: - 资源选择辅助
class MNAssetContainer {
    var assets: [MNAsset] = [MNAsset]()
}
