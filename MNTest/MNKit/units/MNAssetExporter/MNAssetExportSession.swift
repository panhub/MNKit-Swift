//
//  MNAssetExportSession.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/8.
//  视频转码

import Foundation
import AVFoundation
import QuartzCore.CADisplayLink

class MNAssetExportSession: NSObject {
    
    typealias ProgressHandler = (Float) -> Void
    typealias CompletionHandler = (AVAssetExportSession.Status, AVError?) -> Void
    
    /**输出格式**/
    var outputFileType: AVFileType?
    /**裁剪片段**/
    var timeRange: CMTimeRange = .invalid
    /**裁剪画面**/
    var outputRect: CGRect?
    /**预设质量**/
    var presetName: String?
    /**输出路径**/
    var outputURL: URL?
    /**输出分辨率outputRect有效时有效**/
    var renderSize: CGSize?
    /**是否针对网络使用进行优化**/
    var shouldOptimizeForNetworkUse: Bool = true
    /**是否输出视频内容**/
    var isExportVideoTrack: Bool = true
    /**是否输出音频内容**/
    var isExportAudioTrack: Bool = true
    /**获取资源信息**/
    var asset: AVAsset { composition }
    /**查询进度**/
    private weak var displayLink: CADisplayLink?
    /**系统输出使用**/
    private weak var exportSession: AVAssetExportSession?
    /**内部使用**/
    private let composition: AVMutableComposition = AVMutableComposition()
    /**错误信息**/
    private(set) var error: AVError?
    /**进度**/
    private(set) var progress: Float = 0.0
    /**状态**/
    private(set) var status: AVAssetExportSession.Status = .unknown
    /**进度回调**/
    private var progressHandler: ProgressHandler?
    /**结束回调**/
    private var completionHandler: CompletionHandler?
    
    fileprivate override init() {
        super.init()
    }
    
    deinit {
        exportSession = nil
        progressHandler = nil
        completionHandler = nil
        if let displayLink  = displayLink {
            displayLink.isPaused = true
            displayLink.remove(from: .main, forMode: .common)
        }
    }
    
    // MARK: - export
    func exportAsynchronously(progressHandler: MNAssetExportSession.ProgressHandler? = nil, completionHandler: MNAssetExportSession.CompletionHandler? = nil) -> Void {
        guard status != .waiting, status != .exporting else { return }
        error = nil
        progress = 0.0
        status = .waiting
        exportSession = nil
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        DispatchQueue(label: "com.av.asset.export").async {
            self.export()
        }
    }
    
    private func export() {
        
        func finish(error: AVError?) {
            self.error = error
            status = .failed
            completionHandler?(.failed, error)
        }
        
        guard let outputURL = outputURL, outputURL.isFileURL else {
            finish(error: .urlError(.badUrl))
            return
        }
        
        guard composition.tracks.isEmpty == false else {
            finish(error: .trackError(.notFound))
            return
        }
        
        // 重新提取素材
        let videoTrack = composition.track(mediaType: .video)
        let audioTrack = composition.track(mediaType: .audio)
        let asset = AVMutableComposition()
        if isExportVideoTrack, let track = videoTrack {
            let timeRange = CMTIMERANGE_IS_VALID(timeRange) ? timeRange : CMTimeRange(start: .zero, duration: track.timeRange.duration)
            let compositionTrack = asset.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack?.insertTimeRange(timeRange, of: track, at: .zero)
            } catch {
                finish(error: .trackError(.cannotInsert(.video)))
                return
            }
        }
        if isExportAudioTrack, let track = audioTrack {
            let timeRange = CMTIMERANGE_IS_VALID(timeRange) ? timeRange : CMTimeRange(start: .zero, duration: track.timeRange.duration)
            let compositionTrack = asset.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack?.insertTimeRange(timeRange, of: track, at: .zero)
            } catch {
                finish(error: .trackError(.cannotInsert(.audio)))
                return
            }
        }
        
        // 检查输出项
        guard asset.tracks.isEmpty == false else {
            finish(error: .trackError(.notFound))
            return
        }
        
        // 删除本地文件
        let _ = try? FileManager.default.removeItem(at: outputURL)
        let _ = try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // 寻找合适的预设质量<内部封装>
        func presetCompatible(with asset: AVAsset) -> String {
            let presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
            if let presetName = presetName, presets.contains(presetName) {
                return presetName
            }
            var container = [String]()
            if isExportVideoTrack, let _ = composition.track(mediaType: .video) {
                container.append(AVAssetExportPresetHighestQuality)
                container.append(AVAssetExportPreset1280x720)
                container.append(AVAssetExportPresetMediumQuality)
                container.append(AVAssetExportPresetLowQuality)
            }
            if isExportAudioTrack, let _ = composition.track(mediaType: .audio) {
                container.append(AVAssetExportPresetAppleM4A)
            }
            for preset in container {
                if presets.contains(preset) {
                    return preset
                }
            }
            return AVAssetExportPresetPassthrough
        }
        
        // 开始输出
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetCompatible(with: asset)) else {
            finish(error: .exportError(.unsupported))
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType ?? ((isExportVideoTrack && videoTrack != nil) ? .mp4 : .m4a)
        exportSession.shouldOptimizeForNetworkUse = shouldOptimizeForNetworkUse
        if isExportVideoTrack, let track = videoTrack, let outputRect = outputRect, outputRect.isEmpty == false, CMTIMERANGE_IS_VALID(track.timeRange) {
            // 渲染尺寸
            var renderSize = outputRect.size
            if let _ = self.renderSize {
                renderSize = self.renderSize!
                renderSize.width = floor(ceil(renderSize.width)/16.0)*16.0
                renderSize.height = floor(ceil(renderSize.height)/16.0)*16.0
            }
            // 配置画面设置
            let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            videoLayerInstruction.setOpacity(1.0, at: .zero)
            videoLayerInstruction.setTransform(track.transform(withRect: outputRect, renderSize: renderSize), at: .zero)
            
            let videoInstruction = AVMutableVideoCompositionInstruction()
            videoInstruction.layerInstructions = [videoLayerInstruction]
            videoInstruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            
            let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
            videoComposition.renderSize = renderSize
            videoComposition.instructions = [videoInstruction]
            videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(track.nominalFrameRate))
            
            exportSession.videoComposition = videoComposition
        }
        self.exportSession = exportSession
        // 监听
        let displayLink = CADisplayLink(target: self, selector: #selector(tip(_:)))
        displayLink.isPaused = true
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        exportSession.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        // 开始输出
        exportSession.exportAsynchronously { [weak exportSession] in
            self.exportSession = nil
            exportSession?.removeObserver(self, forKeyPath: "status")
            if let displayLink = self.displayLink {
                displayLink.isPaused = true
                displayLink.remove(from: .main, forMode: .common)
            }
            if let error = exportSession?.error {
                self.error = .exportError(.underlyingError(error))
            }
            let status: AVAssetExportSession.Status = exportSession?.status ?? .failed
            self.status = status
            if status != .completed {
                try? FileManager.default.removeItem(at: outputURL)
            }
            self.completionHandler?(status, self.error)
        }
    }
    
    // MARK: - cancel
    func cancel() {
        guard let exportSession = exportSession, exportSession.status == .exporting else { return }
        exportSession.cancelExport()
    }
    
    // MARK: - observe
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let _ = keyPath, keyPath! == "status" else { return }
        guard let status = change?[.newKey] as? Int else { return }
        self.status = AVAssetExportSession.Status(rawValue: status) ?? .unknown
        if status == AVAssetExportSession.Status.exporting.rawValue {
            // 开启轮询
            if let displayLink = self.displayLink {
                displayLink.isPaused = false
            }
        } else if status >= AVAssetExportSession.Status.completed.rawValue {
            // 停止轮询
            if let displayLink = self.displayLink {
                displayLink.isPaused = true
                displayLink.remove(from: .main, forMode: .common)
            }
            if status == AVAssetExportSession.Status.completed.rawValue, progress < 1.0 {
                progress = 1.0
                progressHandler?(progress)
            }
        }
    }
    
    @objc private func tip(_ displayLink: CADisplayLink) {
        guard let exportSession = exportSession, displayLink.isPaused == false else { return }
        progress = exportSession.progress
        progressHandler?(progress)
    }
}

// MARK: - convenience
extension MNAssetExportSession {
    
    convenience init(asset: AVAsset) {
        self.init()
        let _ = composition.append(asset: asset)
    }
    
    convenience init?(fileAtPath filePath: String) {
        self.init(fileOfURL: URL(fileURLWithPath: filePath))
    }
    
    convenience init?(fileOfURL fileURL: URL) {
        guard fileURL.isFileURL, FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        self.init(asset: AVURLAsset(url: fileURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true]))
    }
}

// MARK: - append
extension MNAssetExportSession {
    
    func append(assetOfURL url: URL) {
        let _ = composition.append(assetOfURL: url)
    }
    
    func append(asset: AVAsset) {
        let _ = composition.append(asset: asset)
    }
    
    func append(assetOfURL url: URL, mediaType: AVMediaType) {
        let _ = composition.append(assetOfURL: url, mediaType: mediaType)
    }
    
    func append(track: AVAssetTrack) {
        let _ = composition.append(track: track)
    }
}
