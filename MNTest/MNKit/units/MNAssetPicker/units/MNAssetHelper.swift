//
//  MNAssetHelper.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/28.
//  辅助方法

import Foundation
import Photos
import UIKit

class MNAssetHelper {
    /**唯一实例**/
    fileprivate static let helper: MNAssetHelper = MNAssetHelper()
    /**视频请求参数**/
    fileprivate lazy var videoOptions: PHVideoRequestOptions = {
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        return options
    }()
    /**图片请求参数**/
    fileprivate lazy var imageOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.version = .current
        options.resizeMode = .fast
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        return options
    }()
    /**LivePhoto请求参数**/
    @available(iOS 9.1, *)
    fileprivate lazy var livePhotoOptions: PHLivePhotoRequestOptions = {
        let options = PHLivePhotoRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        return options
    }()
    /**外部禁止实例化**/
    private init() {}
}

// MARK: - Get Collection
extension MNAssetHelper {
    /**
     获取相簿
     @param config 配置信息
     @param completion 完成回调
     */
    static func albums(options: MNAssetPickerOptions, completion: @escaping ([MNAssetAlbum])->Void) {
        DispatchQueue.global().async {
            var collections: [MNAssetAlbum] = [MNAssetAlbum]()
            let smartResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
            smartResult.enumerateObjects { obj, _, stop in
                if obj.isCameraCollection {
                    collections.append(MNAssetHelper.collection(from: obj, options: options))
                    stop.pointee = true
                }
            }
            guard options.isAllowsPickingAlbum else {
                DispatchQueue.main.async {
                    completion(collections)
                }
                return
            }
            let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
            fetchResult.enumerateObjects { obj, _, _ in
                let collection = MNAssetHelper.collection(from: obj, options: options)
                if collection.assets.count <= 0, options.isShowEmptyAlbum == false { return }
                collections.append(collection)
            }
            DispatchQueue.main.async {
                completion(collections)
            }
        }
    }
    
    /**
     获取相簿数据
     @param collection 系统资源集合
     @param config 配置信息
     */
    static func collection(from collection: PHAssetCollection, options: MNAssetPickerOptions) -> MNAssetAlbum {
        let fetchOptions = PHFetchOptions()
        if options.isAllowsPickingVideo == false {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        } else if options.isAllowsPickingPhoto == false, options.isAllowsPickingGif == false, options.isAllowsPickingLivePhoto == false {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        } else {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        }
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: options.isSortAscending)]
        // 检索数据
        var assets: [MNAsset] = [MNAsset]()
        let result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        assets.append(contentsOf: fetchAssets(result: result, options: options))
#if arch(i386) || arch(x86_64)
#else
        // 手机设备就添加拍摄入口
#endif
        let assetCollection = MNAssetAlbum()
        assetCollection.result = result
        assetCollection.collection = collection
        assetCollection.title = collection.localizedTitle ?? "未知相簿"
        if collection.isCameraCollection {
            assetCollection.title = "最近项目"
        }
        assetCollection.add(assets: assets)
        return assetCollection
    }
    
    static func fetchAssets(result: PHFetchResult<PHAsset>, options: MNAssetPickerOptions) -> [MNAsset] {
        var assets:[MNAsset] = [MNAsset]()
        result.enumerateObjects { pha, _, _ in
            var type = MNAssetHelper.assetType(pha)
            if type == .video {
                let duration: TimeInterval = floor(pha.duration)
                if (options.minExportDuration > 0.0 && duration < options.minExportDuration) || (options.maxExportDuration > 0.0 && duration > options.maxExportDuration && (options.isAllowsEditing == false || options.maxPickingCount > 1 || options.isAllowsMultiplePickingVideo == false)) { return }
            } else if type == .gif {
                guard options.isAllowsPickingGif else { return }
                if options.isUsingPhotoPolicyPickingGif { type = .photo }
            } else if type == .livePhoto {
                guard options.isAllowsPickingLivePhoto else { return }
                if options.isUsingPhotoPolicyPickingLivePhoto { type = .photo }
            }
            let asset = MNAsset()
            asset.type = type
            asset.phAsset = pha
            asset.renderSize = options.renderSize
            if type == .video {
                asset.duration = pha.duration
            }
            assets.append(asset)
        }
        return assets
    }
    
    static func assetType(_ asset: PHAsset) -> MNAsset.AssetType {
        var type: MNAsset.AssetType = .photo
        switch asset.mediaType {
        case .image:
            if let filename = asset.value(forKey: "filename") as? NSString, filename.pathExtension.lowercased().contains("gif") {
                type = .gif
            } else if #available(iOS 9.1, *) {
                if asset.mediaSubtypes.contains(.photoLive) {
                    type = .livePhoto
                }
            }
        case .video:
            type = .video
        default:
            break
        }
        return type
    }
}

// MARK: - Get Thumbnail
extension MNAssetHelper {
    // 展示时请求缩略图(多次回调)
    static func profile(asset: MNAsset, options: MNAssetPickerOptions) {
        // 缩略图
        if let _ = asset.thumbnail {
            asset.thumbnailUpdateHandler?(asset)
        } else {
            guard let phAsset = asset.phAsset else { return }
            let imageOptions = MNAssetHelper.helper.imageOptions
            imageOptions.resizeMode = .fast
            imageOptions.deliveryMode = .opportunistic
            imageOptions.isNetworkAccessAllowed = true
            asset.requestId = PHImageManager.default().requestImage(for: phAsset, targetSize: asset.renderSize, contentMode: .aspectFill, options: imageOptions) { [weak asset] result, info in
                // 可能调用多次
                guard let asset = asset else { return }
                let isCancelled: Bool = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
                guard isCancelled == false else { return }
                guard let image = result?.resizingOrientation else { return }
                let isDegraded: Bool = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
                if isDegraded {
                    // 衰减图片
                    asset.degradedImage = image
                    DispatchQueue.main.async {
                        asset.thumbnailUpdateHandler?(asset)
                    }
                } else {
                    // 缩略图
                    asset.degradedImage = nil
                    asset.update(thumbnail: image)
                    asset.requestId = PHInvalidImageRequestID
                }
            }
        }
        // 源文件是否是云端/文件大小
        if asset.source == .unknown {
            options.queue.async { [weak options] in
                var isClould: Bool = true
                guard let phAsset = asset.phAsset else { return }
                let resources = PHAssetResource.assetResources(for: phAsset)
                for resource in resources {
                    isClould = (resource.value(forKey: "locallyAvailable") as? Bool ?? false) == false
                }
                asset.update(source: isClould ? .cloud : .local)
                
                if let options = options, options.isShowFileSize, asset.fileSize < 0, isClould == false {
                    // 获取大小
                    var fileSize: Int64 = 0
                    let resources = PHAssetResource.assetResources(for: phAsset)
                    for resource in resources {
                        fileSize += (resource.value(forKey: "fileSize") as? Int64 ?? 0)
                    }
                    asset.update(fileSize: fileSize)
                }
            }
        }
    }
    // 预览时请求缩略图(仅回调一次)
    static func thumbnail(asset: MNAsset, completion: ((MNAsset, UIImage)->Void)?) {
        if let image = asset.thumbnail {
            completion?(asset, image)
            return
        }
        guard let phAsset = asset.phAsset else { return }
        let options = MNAssetHelper.helper.imageOptions
        options.resizeMode = .fast
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        asset.requestId = PHImageManager.default().requestImage(for: phAsset, targetSize: asset.renderSize, contentMode: .aspectFill, options: options) { [weak asset] result, info in
            guard let asset = asset else { return }
            asset.requestId = PHInvalidImageRequestID
            let isCancelled: Bool = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
            guard isCancelled == false else { return }
            guard let image = result?.resizingOrientation else { return }
            DispatchQueue.main.async {
                completion?(asset, image)
            }
        }
    }
}

// MARK: - Content
extension MNAssetHelper {
    // 预览时请求内容
    static func content(asset: MNAsset, progress: ((Double, Error?, MNAsset)->Void)?, completion: ((MNAsset)->Void)?) {
        if let _ = asset.content {
            completion?(asset)
            return
        }
        guard let phAsset = asset.phAsset else {
            progress?(0.0, nil, asset)
            completion?(asset)
            return
        }
        if asset.type == .video {
            let options = MNAssetHelper.helper.videoOptions
            options.version = .current
            options.deliveryMode = .automatic;
            options.isNetworkAccessAllowed = true
            options.progressHandler = { pro, error, _, _ in
                DispatchQueue.main.async {
                    asset.progress = pro
                    progress?(pro, error, asset)
                }
            }
            asset.downloadId = PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { [weak asset] result, _, info in
                guard let asset = asset else { return }
                asset.progress = 0.0
                asset.downloadId = PHInvalidImageRequestID
                let isCancelled: Bool = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
                guard isCancelled == false else { return }
                if let avAsset = result as? AVURLAsset {
                    if asset.fileSize <= 0 {
                        do {
                            let attributes = try FileManager.default.attributesOfItem(atPath: avAsset.url.path)
                            if let fileSize = (attributes[FileAttributeKey.size] as? NSNumber)?.int64Value, fileSize >= 0 {
                                asset.update(fileSize: fileSize)
                            }
                        } catch {}
                    }
                    asset.content = avAsset.url.path
                }
                DispatchQueue.main.async {
                    completion?(asset)
                }
            }
        } else if asset.type == .livePhoto {
            if #available(iOS 9.1, *) {
                let options = MNAssetHelper.helper.livePhotoOptions
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                options.progressHandler = { pro, error, _, _ in
                    DispatchQueue.main.async {
                        asset.progress = pro
                        progress?(pro, error, asset)
                    }
                }
                asset.downloadId = PHImageManager.default().requestLivePhoto(for: phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { [weak asset] result, info in
                    guard let asset = asset else { return }
                    asset.progress = 0.0
                    asset.downloadId = PHInvalidImageRequestID
                    let isCancelled: Bool = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
                    guard isCancelled == false else { return }
                    if let livePhoto = result {
                        asset.content = livePhoto
                    }
                    DispatchQueue.main.async {
                        completion?(asset)
                    }
                }
            }
        } else {
            let options = MNAssetHelper.helper.imageOptions
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat;
            options.progressHandler = { pro, error, _, _ in
                DispatchQueue.main.async {
                    asset.progress = pro
                    progress?(pro, error, asset)
                }
            }
            let resultHandler: (Data?, String?, Any, [AnyHashable : Any]?) -> Void = { [weak asset] imageData, _, _, info in
                guard let asset = asset else { return }
                asset.progress = 0.0
                asset.downloadId = PHInvalidImageRequestID
                let isCancelled: Bool = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
                guard isCancelled == false else { return }
                let result: UIImage? = asset.type == .gif ? UIImage.image(contentsOfData: imageData) : (imageData == nil ? nil : UIImage(data: imageData!))
                if let image = result {
                    if image.isAnimatedImage {
                        asset.content = image
                    } else {
                        asset.content = image.resizingOrientation
                    }
                    if asset.fileSize <= 0 {
                        let fileSize = Int64(imageData!.count)
                        asset.update(fileSize: fileSize)
                    }
                }
                DispatchQueue.main.async {
                    completion?(asset)
                }
            }
            if #available(iOS 13.0, *) {
                asset.downloadId = PHImageManager.default().requestImageDataAndOrientation(for: phAsset, options: options, resultHandler: resultHandler)
            } else {
                asset.downloadId = PHImageManager.default().requestImageData(for: phAsset, options: options, resultHandler: resultHandler)
            }
        }
    }
}

// MARK: - Export
extension MNAssetHelper {
    
    // 异步导出资源内容
    static func export(assets: [MNAsset], options: MNAssetPickerOptions, progress: ((Int, Int)->Void)?, completion: @escaping ([MNAsset])->Void) {
        guard assets.count > 0 else {
            completion([])
            return
        }
        export(assets: assets, index: 0, options: options, container: MNAssetContainer(), progress: progress, completion: completion)
    }
    
    private static func export(assets: [MNAsset], index: Int, options: MNAssetPickerOptions, container: MNAssetContainer, progress: ((Int, Int)->Void)?, completion: @escaping ([MNAsset])->Void) {
        DispatchQueue.global().async {
            guard index < assets.count else {
                completion(container.assets)
                return
            }
            progress?(index, assets.count)
            MNAssetHelper.export(asset: assets[index], options: options) { asset in
                if asset.state == .normal {
                    container.assets.append(asset)
                }
                MNAssetHelper.export(assets: assets, index: index + 1, options: options, container: container, progress: progress, completion: completion)
            }
        }
    }
    
    // 导出资源内容
    private static func export(asset: MNAsset, options: MNAssetPickerOptions, completion: ((MNAsset)->Void)?) {
        guard let phAsset = asset.phAsset else {
            asset.state = .failed
            completion?(asset)
            return
        }
        // 开始下载数据
        asset.update(state: .downloading)
        if asset.type == .video {
            let videoOptions = MNAssetHelper.helper.videoOptions
            videoOptions.version = .current
            videoOptions.isNetworkAccessAllowed = true
            videoOptions.deliveryMode = .highQualityFormat;
            PHImageManager.default().requestAVAsset(forVideo: phAsset, options: videoOptions) { result, _, _ in
                if let avAsset = result as? AVURLAsset {
                    if options.isAllowsMovExporting == false, avAsset.url.pathExtension.lowercased().contains("mov") {
                        let outputURL: URL = options.exportURL(pathExtension: "mp4")
                        try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                        if let exportSession = AVAssetExportSession(asset: avAsset, presetName: options.exportPreset ?? AVAssetExportPresetHighestQuality) {
                            exportSession.outputURL = outputURL
                            exportSession.outputFileType = .mp4
                            exportSession.shouldOptimizeForNetworkUse = true
                            exportSession.exportAsynchronously { [weak exportSession] in
                                let status = exportSession?.status ?? .failed
                                if status == .completed, FileManager.default.fileExists(atPath: outputURL.path) {
                                    asset.content = outputURL.path
                                    asset.update(state: .normal)
                                } else {
                                    try? FileManager.default.removeItem(at: outputURL)
                                    asset.update(state: .failed)
                                }
                                DispatchQueue.main.async {
                                    completion?(asset)
                                }
                            }
                        } else {
                            asset.update(state: .failed)
                            DispatchQueue.main.async {
                                completion?(asset)
                            }
                        }
                    } else {
                        asset.content = avAsset.url.path
                        asset.update(state: .normal)
                        DispatchQueue.main.async {
                            completion?(asset)
                        }
                    }
                } else {
                    asset.update(state: .failed)
                    DispatchQueue.main.async {
                        completion?(asset)
                    }
                }
            }
        } else if asset.type == .livePhoto {
            if #available(iOS 9.1, *) {
                let livePhotoOptions = MNAssetHelper.helper.livePhotoOptions
                livePhotoOptions.isNetworkAccessAllowed = true
                livePhotoOptions.deliveryMode = .highQualityFormat
                PHImageManager.default().requestLivePhoto(for: phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: livePhotoOptions) { result, _ in
                    if let livePhoto = result {
                        if options.shouldExportLiveResource {
                            MNAssetHelper.exportLivePhoto(livePhoto) { imageUrl, videoUrl in
                                if let image = imageUrl, let video = videoUrl {
                                    livePhoto.imageFileURL = image
                                    livePhoto.videoFileURL = video
                                    asset.content = livePhoto
                                    asset.update(state: .normal)
                                    DispatchQueue.main.async {
                                        completion?(asset)
                                    }
                                } else {
                                    asset.update(state: .failed)
                                    DispatchQueue.main.async {
                                        completion?(asset)
                                    }
                                }
                            }
                        } else {
                            asset.content = livePhoto
                            asset.update(state: .normal)
                            DispatchQueue.main.async {
                                completion?(asset)
                            }
                        }
                    } else {
                        asset.update(state: .failed)
                        DispatchQueue.main.async {
                            completion?(asset)
                        }
                    }
                }
            }
        } else {
            let imageOptions = MNAssetHelper.helper.imageOptions
            imageOptions.isNetworkAccessAllowed = true
            imageOptions.deliveryMode = .highQualityFormat;
            let resultHandler: (Data?, String?, Any, [AnyHashable : Any]?) -> Void = { imageData, _, _, _ in
                var image: UIImage?
                if let result = asset.type == .gif ? UIImage.image(contentsOfData: imageData) : (imageData == nil ? nil : UIImage(data: imageData!)) {
                    if result.isAnimatedImage {
                        image = result
                    } else {
                        // 判断是否需要转化heif/heic格式图片
                        if #available(iOS 10.0, *), options.isAllowsHeifcExporting == false, phAsset.isHeifc, let ciImage = CIImage(data: imageData!), let colorSpace = ciImage.colorSpace, let jpgData = CIContext().jpegRepresentation(of: ciImage, colorSpace: colorSpace, options: [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String):options.compressionQuality]) {
                            image = UIImage(data: jpgData)
                        } else {
                            image = result
                        }
                        image = image?.resizingOrientation
                        if options.compressionQuality < 1.0 {
                            image = image?.optimized(compressionQuality: max(options.compressionQuality, 0.1))
                        }
                    }
                }
                if let _ = image {
                    asset.content = image
                    asset.update(state: .normal)
                } else {
                    asset.update(state: .failed)
                }
                DispatchQueue.main.async {
                    completion?(asset)
                }
            }
            if #available(iOS 13.0, *) {
                PHImageManager.default().requestImageDataAndOrientation(for: phAsset, options: imageOptions, resultHandler: resultHandler)
            } else {
                PHImageManager.default().requestImageData(for: phAsset, options: imageOptions, resultHandler: resultHandler)
            }
        }
    }
}

// MARK: - Cancel
extension MNAssetHelper {
    static func cancel(request asset: MNAsset) {
        let requestId = asset.requestId
        guard requestId != PHInvalidImageRequestID else { return }
        asset.requestId = PHInvalidImageRequestID
        PHImageManager.default().cancelImageRequest(requestId)
    }
    static func cancel(download asset: MNAsset) {
        let downloadId = asset.downloadId
        guard downloadId != PHInvalidImageRequestID else { return }
        asset.downloadId = PHInvalidImageRequestID
        PHImageManager.default().cancelImageRequest(downloadId)
    }
}

// MARK: - 相册操作
extension MNAssetHelper {
    
    @objc static func deleteAssets(_ assets: [PHAsset], completion: ((Error?)->Void)?) {
        DispatchQueue.global().async {
            guard assets.count > 0 else {
                DispatchQueue.main.async {
                    completion?(MNPHError.deleteError(.isEmpty))
                }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            } completionHandler: { flag, error in
                DispatchQueue.main.async {
                    if flag {
                        completion?(nil)
                    } else {
                        completion?(error == nil ? MNPHError.deleteError(.unknown) : MNPHError.deleteError(.underlyingError(error!)))
                    }
                }
            }
        }
    }
    
    @objc static func writeImage(toAlbum image: Any, completion: ((String?, Error?)->Void)?) {
        writeAssets([image], toAlbum: nil) { identifiers, error in
            completion?(identifiers?.first, error)
        }
    }
    
    @objc static func writeVideo(toAlbum video: Any, completion: ((String?, Error?)->Void)?) {
        writeAssets([video], toAlbum: nil) { identifiers, error in
            completion?(identifiers?.first, error)
        }
    }
    
    @available(iOS 9.1, *)
    @objc static func writeLivePhoto(toAlbum livePhoto: PHLivePhoto, completion: ((String?, Error?)->Void)?) {
        writeAssets([livePhoto], toAlbum: nil) { identifiers, error in
            completion?(identifiers?.first, error)
        }
    }
    
    @objc static func writeAssets(_ assets: [Any], toAlbum title: String? = nil, completion: (([String]?, Error?)->Void)?) {
        DispatchQueue.global().async {
            var identifiers: [String] = [String]()
            var placeholders: [PHObjectPlaceholder] = [PHObjectPlaceholder]()
            PHPhotoLibrary.shared().performChanges {
                for var asset in assets {
                    // 转换资源
                    if asset is String {
                        guard let path = asset as? String, FileManager.default.fileExists(atPath: path) else { continue }
                        asset = URL(fileURLWithPath: path) as AnyObject
                    } else if asset is Data {
                        guard let image = UIImage(data: asset as! Data) else { continue }
                        asset = image
                    }
                    // 图片/视频
                    var placeholder: PHObjectPlaceholder?
                    if asset is UIImage {
                        placeholder = PHAssetChangeRequest.creationRequestForAsset(from: asset as! UIImage).placeholderForCreatedAsset
                    } else if asset is URL {
                        guard let url = asset as? URL, url.isFileURL, FileManager.default.fileExists(atPath: url.path) else { continue }
                        if ["mp4", "mov", "3gp"].contains(url.pathExtension.lowercased()) {
                            placeholder = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)?.placeholderForCreatedAsset
                        } else if ["jpg", "png", "jpeg", "gif", "heif"].contains(url.pathExtension.lowercased()) {
                            placeholder = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)?.placeholderForCreatedAsset
                        }
                    }
                    // LivePhoto
                    if #available(iOS 9.1, *) {
                        if asset is PHLivePhoto {
                            let videoURL = (asset as? PHLivePhoto)?.videoFileURL
                            let imageURL = (asset as? PHLivePhoto)?.imageFileURL
                            guard let video = videoURL, FileManager.default.fileExists(atPath: video.path), let image = imageURL, FileManager.default.fileExists(atPath: image.path) else { continue }
                            let request = PHAssetCreationRequest.forAsset()
                            request.addResource(with: .video, fileURL: video, options: nil)
                            request.addResource(with: .photo, fileURL: image, options: nil)
                            placeholder = request.placeholderForCreatedAsset
                        } else if asset is [MNLivePhotoResourceKey:AnyObject] {
                            guard let dictionary = asset as? [MNLivePhotoResourceKey:AnyObject] else { continue }
                            var videoURL: URL?, imageURL: URL?
                            if let path = dictionary[MNLivePhotoImageUrlKey] as? String, FileManager.default.fileExists(atPath: path) {
                                if (path as NSString).pathExtension.lowercased() == "jpg" || (path as NSString).pathExtension.lowercased() == "jpeg" {
                                    imageURL = URL(fileURLWithPath: path)
                                }
                            } else if let url = dictionary[MNLivePhotoImageUrlKey] as? URL, FileManager.default.fileExists(atPath: url.path) {
                                if url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg" {
                                    imageURL = url
                                }
                            }
                            if let path = dictionary[MNLivePhotoVideoUrlKey] as? String, FileManager.default.fileExists(atPath: path), (path as NSString).pathExtension.lowercased() == "mov" {
                                videoURL = URL(fileURLWithPath: path)
                            } else if let url = dictionary[MNLivePhotoVideoUrlKey] as? URL, FileManager.default.fileExists(atPath: url.path), url.pathExtension.lowercased() == "mov" {
                                videoURL = url
                            }
                            guard let video = videoURL, let image = imageURL else { continue }
                            let request = PHAssetCreationRequest.forAsset()
                            request.addResource(with: .video, fileURL: video, options: nil)
                            request.addResource(with: .photo, fileURL: image, options: nil)
                            placeholder = request.placeholderForCreatedAsset
                        } else if asset is [AnyObject] {
                            guard let array = asset as? [AnyObject], array.count == 2 else { continue }
                            var videoURL: URL?, imageURL: URL?
                            for item in array {
                                if item is String {
                                    guard let path = item as? String, FileManager.default.fileExists(atPath: path) else { continue }
                                    if (path as NSString).pathExtension.lowercased() == "mov" {
                                        videoURL = URL(fileURLWithPath: path)
                                    } else if (path as NSString).pathExtension.lowercased() == "jpg" || (path as NSString).pathExtension.lowercased() == "jpeg" {
                                        imageURL = URL(fileURLWithPath: path)
                                    }
                                } else if item is URL {
                                    guard let url = item as? URL, FileManager.default.fileExists(atPath: url.path) else { continue }
                                    if url.pathExtension.lowercased() == "mov" {
                                        videoURL = url
                                    } else if url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg" {
                                        imageURL = url
                                    }
                                }
                            }
                            guard let video = videoURL, let image = imageURL else { continue }
                            let request = PHAssetCreationRequest.forAsset()
                            request.addResource(with: .video, fileURL: video, options: nil)
                            request.addResource(with: .photo, fileURL: image, options: nil)
                            placeholder = request.placeholderForCreatedAsset
                        }
                    }
                    guard let _ = placeholder else { continue }
                    placeholders.append(placeholder!)
                    identifiers.append(placeholder!.localIdentifier)
                }
                if placeholders.count > 0 {
                    MNAssetHelper.creationRequestForAssetCollection(withTitle: title)?.addAssets(placeholders as NSFastEnumeration)
                }
            } completionHandler: { result, error in
                DispatchQueue.main.async {
                    if result {
                        completion?(identifiers, nil)
                    } else {
                        completion?(nil, (error == nil ? MNPHError.writeError(.unknown) : MNPHError.writeError(.underlyingError(error!))))
                    }
                }
            }
        }
    }
    
    private static func creationRequestForAssetCollection(withTitle title: String? = nil) -> PHAssetCollectionChangeRequest? {
        var collection: PHAssetCollection?
        var ctitle: String = title ?? ""
        ctitle = ctitle.count == 0 ? ((Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? "新建相簿") : ctitle
        // 寻找相簿
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        result.enumerateObjects { obj, _, stop in
            if let localizedTitle = obj.localizedTitle, localizedTitle == ctitle {
                collection = obj
                stop.pointee = true
            }
        }
        guard let _ = collection else {
            return PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: ctitle)
        }
        return PHAssetCollectionChangeRequest(for: collection!)
    }
}

// MARK: - LivePhoto
@available(iOS 9.1, *)
extension MNAssetHelper {
    // 合成
    @objc class func requestLivePhoto(resourceFileURLs urls: [URL], completion: ((PHLivePhoto?, Error?)->Void)?) {
        DispatchQueue.global().async {
            var videoURL: URL?
            var imageURL: URL?
            for url in urls {
                guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else { continue }
                let pathExtension = url.pathExtension.lowercased()
                try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                if pathExtension == "mov" {
                    videoURL = url
                } else if pathExtension == "jpeg" || pathExtension == "jpg" {
                    imageURL = url
                }
            }
            guard let video = videoURL, let image = imageURL else {
                DispatchQueue.main.async {
                    completion?(nil, MNPHError.livePhotoError(.fileNotExist))
                }
                return
            }
            PHLivePhoto.request(withResourceFileURLs: [video, image], placeholderImage: nil, targetSize: .zero, contentMode: .aspectFit) { photo, info in
                if let livePhoto = photo {
                    guard ((info[PHLivePhotoInfoIsDegradedKey] as? NSNumber)?.boolValue ?? false) == false else { return }
                    livePhoto.videoFileURL = video
                    livePhoto.imageFileURL = image
                    DispatchQueue.main.async {
                        completion?(livePhoto, nil)
                    }
                } else {
                    let error = info[PHLivePhotoInfoErrorKey] as? Error
                    DispatchQueue.main.async {
                        completion?(nil, (error == nil ? MNPHError.livePhotoError(.requestFailed) : MNPHError.livePhotoError(.underlyingError(error!))))
                    }
                }
            }
        }
    }
    
    // 导出
    @objc static func exportLivePhoto(_ livePhoto: PHLivePhoto, completion: ((URL?, URL?)->Void)?) {
        let videoUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("\(Int(Date().timeIntervalSince1970*1000.0))").appendingPathExtension("MOV")
        let imageUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("\(Int(Date().timeIntervalSince1970*1000.0))").appendingPathExtension("JPG")
        exportLivePhoto(livePhoto, imageUrl: imageUrl, videoUrl: videoUrl) { result in
            if result {
                completion?(imageUrl, videoUrl)
            } else {
                completion?(nil, nil)
            }
        }
    }
    
    @objc static func exportLivePhoto(_ livePhoto: PHLivePhoto, imageUrl: URL, videoUrl: URL, completion: ((Bool)->Void)?) {
        for url in [imageUrl, videoUrl] {
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        }
        let group = DispatchGroup()
        let resources = PHAssetResource.assetResources(for: livePhoto)
        for resource in resources {
            group.enter()
            let buffer = PHLivePhotoBuffer()
            buffer.type = resource.type
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            PHAssetResourceManager.default().requestData(for: resource, options: options) { data in
                buffer.data.append(contentsOf: data)
            } completionHandler: { error in
                if error == nil {
                    if buffer.type == .pairedVideo {
                        try? buffer.data.write(to: videoUrl, options: .atomic)
                    } else {
                        try? buffer.data.write(to: imageUrl, options: .atomic)
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            if FileManager.default.fileExists(atPath: imageUrl.path), FileManager.default.fileExists(atPath: videoUrl.path) {
                completion?(true)
            } else {
                try? FileManager.default.removeItem(at: videoUrl)
                try? FileManager.default.removeItem(at: imageUrl)
                completion?(false)
            }
        }
    }
}
