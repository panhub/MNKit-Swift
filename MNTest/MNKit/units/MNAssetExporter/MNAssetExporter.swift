//
//  MNAssetExporter.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/30.
//  资源输入

import Foundation
import AVFoundation
import ObjectiveC

class MNAssetExporter: NSObject {
    
    typealias ProgressHandler = (Float) -> Void
    typealias CompletionHandler = (AVAssetExportSession.Status, AVError?) -> Void
    
    /**裁剪片段**/
    var timeRange: CMTimeRange = .invalid
    /**裁剪画面**/
    var outputRect: CGRect?
    /**预设质量**/
    var presetName: String?
    /**帧率**/
    var frameRate: Int = 30
    /**输出路径**/
    var outputURL: URL?
    /**输出分辨率outputRect有效时有效**/
    var renderSize: CGSize?
    /**使用高比特率输出**/
    var shouldHighBitRateForUse: Bool = false
    /**是否针对网络使用进行优化**/
    var shouldOptimizeForNetworkUse: Bool = false
    /**是否输出视频内容**/
    var isExportVideoTrack: Bool = true
    /**是否输出音频内容**/
    var isExportAudioTrack: Bool = true
    /**获取资源信息**/
    var asset: AVAsset { composition }
    /**内部使用**/
    private lazy var composition: AVMutableComposition = {
        return AVMutableComposition()
    }()
    /**视频输入**/
    private var videoInput: AVAssetWriterInput?
    /**音频输入**/
    private var audioInput: AVAssetWriterInput?
    /**视频输出**/
    private var videoOutput: AVAssetReaderOutput?
    /**音频输出**/
    private var audioOutput: AVAssetReaderOutput?
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
        progressHandler = nil
        completionHandler = nil
    }
    
    // MARK: - export
    func exportAsynchronously(progressHandler: MNAssetExporter.ProgressHandler? = nil, completionHandler: MNAssetExporter.CompletionHandler? = nil) -> Void {
        guard status != .exporting else { return }
        error = nil
        progress = 0.0
        status = .exporting
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        DispatchQueue(label: "com.mn.asset.export").async {
            self.export()
        }
    }
    
    // MARK: - export
    private func export() {
        
        // 检查输出路径
        guard let outputURL = outputURL, outputURL.isFileURL else {
            finish(error: .urlError(.badUrl))
            return
        }
        
        // 检查文件
        guard composition.tracks.isEmpty == false else {
            finish(error: .trackError(.notFound))
            return
        }
        
        // 检查输出画面大小
        let naturalSize: CGSize = composition.track(mediaType: .video)?.naturalSizeOfVideo ?? .zero
        let outputRect = self.outputRect ?? CGRect(x: 0.0, y: 0.0, width: naturalSize.width, height: naturalSize.height)
        if isExportVideoTrack, outputRect.size == .zero {
            finish(error: .trackError(.outputRectIsZero))
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
        
        // 检查文件完整性
        guard asset.tracks.isEmpty == false else {
            finish(error: .trackError(.notFound))
            return
        }
        
        // 文件读取
        var assetReader: AVAssetReader?
        do {
            assetReader = try AVAssetReader(asset: asset)
            assetReader?.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        } catch {
            finish(error: .readError(.underlyingError(error)))
            return
        }
        
        guard let reader = assetReader else {
            finish(error: .readError(.cannotCreateReader))
            return
        }
        
        // 文件写入
        var assetWriter: AVAssetWriter?
        let fileType: AVFileType = (videoTrack != nil && isExportVideoTrack) ? .mp4 : .m4a
        do {
            assetWriter = try AVAssetWriter(url: outputURL, fileType: fileType)
        } catch {
            finish(error: .writeError(.underlyingError(error)))
            return
        }
        
        guard let writer = assetWriter else {
            finish(error: .writeError(.cannotCreateWriter))
            return
        }
        
        // 配置视频
        if let track = videoTrack, isExportVideoTrack {
            // Output
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
            
            let videoOutput = AVAssetReaderVideoCompositionOutput(videoTracks: asset.tracks(withMediaType: .video), videoSettings: [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
            videoOutput.alwaysCopiesSampleData = false
            guard reader.canAdd(videoOutput) else {
                finish(error: .readError(.cannotAddVoidOutput))
                return
            }
            reader.add(videoOutput)
            videoOutput.videoComposition = videoComposition
            self.videoOutput = videoOutput
            
            // Input
            let width = Int(renderSize.width)
            let height = Int(renderSize.height)
            // 比特率
            var averageDataRate: Float = 0.0
            if shouldHighBitRateForUse, shouldOptimizeForNetworkUse == false {
                let bitsPerPixel: Float = width*height <= (640*480) ? 4.05 : 10.1
                averageDataRate = Float(width*height)*bitsPerPixel
            } else {
                let videoDataRate: Float = track.estimatedDataRate
                let audioDataRate: Float = audioTrack?.estimatedDataRate ?? 0.0
                averageDataRate = videoDataRate + audioDataRate
                if averageDataRate <= audioDataRate {
                    averageDataRate = Float(width*height)*7.5
                }
            }
            // 压缩级别
            var profileLevel: String = AVVideoProfileLevelH264BaselineAutoLevel
            if shouldOptimizeForNetworkUse == false {
                let presetName = presetName ?? AVAssetExportPresetHighestQuality
                if presetName == AVAssetExportPresetHighestQuality || presetName == AVAssetExportPreset3840x2160 || presetName == AVAssetExportPreset1920x1080 {
                    profileLevel = AVVideoProfileLevelH264HighAutoLevel
                } else if presetName == AVAssetExportPresetMediumQuality || presetName == AVAssetExportPreset1280x720  || presetName == AVAssetExportPreset960x540 {
                    profileLevel = AVVideoProfileLevelH264MainAutoLevel
                } else if presetName == AVAssetExportPresetLowQuality || presetName == AVAssetExportPreset640x480 {
                    profileLevel = AVVideoProfileLevelH264BaselineAutoLevel
                }
            }
            // 帧率
            let frameRate: Int = min(max(30, self.frameRate), 120)
            var h264Codec: String
            if #available(iOS 11.0, *) {
                h264Codec = AVVideoCodecType.h264.rawValue
            } else {
                h264Codec = AVVideoCodecH264
            }
            let videoSettings: [String:Any] = [AVVideoWidthKey:width, AVVideoHeightKey:height, AVVideoCodecKey:h264Codec, AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill, AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:ceil(averageDataRate), AVVideoProfileLevelKey: profileLevel, AVVideoExpectedSourceFrameRateKey:frameRate, AVVideoMaxKeyFrameIntervalKey: frameRate, AVVideoCleanApertureKey:[AVVideoCleanApertureWidthKey:width, AVVideoCleanApertureHeightKey:height, AVVideoCleanApertureHorizontalOffsetKey:10, AVVideoCleanApertureVerticalOffsetKey:10], AVVideoPixelAspectRatioKey:[AVVideoPixelAspectRatioHorizontalSpacingKey:1, AVVideoPixelAspectRatioVerticalSpacingKey:1]]]
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            guard writer.canAdd(videoInput) else {
                finish(error: .writeError(.cannotAddVoidInput))
                return
            }
            writer.add(videoInput)
            self.videoInput = videoInput
        }
        
        // 配置音频
        if let _ = audioTrack, isExportAudioTrack {
            // Output
            let audioOutput = AVAssetReaderAudioMixOutput(audioTracks: asset.tracks(withMediaType: .audio), audioSettings: [AVFormatIDKey:kAudioFormatLinearPCM])
            audioOutput.alwaysCopiesSampleData = false
            guard reader.canAdd(audioOutput) else {
                finish(error: .readError(.cannotAddAudioOutput))
                return
            }
            reader.add(audioOutput)
            self.audioOutput = audioOutput
            
            // Input
            var channelLayout: AudioChannelLayout = AudioChannelLayout()
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
            channelLayout.mChannelBitmap = .bit_Left
            channelLayout.mNumberChannelDescriptions = 0
            let channelLayoutData: Data = Data(bytes: &channelLayout, count: MemoryLayout.size(ofValue: channelLayout))
            let audioSettings: [String:Any] = [AVFormatIDKey:kAudioFormatMPEG4AAC, AVSampleRateKey:44100, AVNumberOfChannelsKey:2, AVChannelLayoutKey:channelLayoutData]
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            guard writer.canAdd(audioInput) else {
                finish(error: .writeError(.cannotAddAudioInput))
                return
            }
            writer.add(audioInput)
            self.audioInput = audioInput
        }
        
        guard reader.outputs.count == writer.inputs.count, reader.outputs.count != 0 else {
            finish(error: .assetError(.notFound))
            return
        }
        
        // 删除本地文件
        let _ = try? FileManager.default.removeItem(at: outputURL)
        let _ = try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // 开始读取文件
        guard reader.startReading() else {
            finish(error: .readError(.cannotReading))
            return
        }
        
        // 开始写入文件
        guard writer.startWriting() else {
            reader.cancelReading()
            finish(error: .writeError(.cannotWriting))
            return
        }
        writer.startSession(atSourceTime: .zero)
        
        // group组为了等待结果回调, 读写队列为串行队列是为了避免数据错乱
        let group = DispatchGroup()
        
        // 视频数据转化
        if let _ = videoInput, let _ = videoOutput {
            group.enter()
            let duration = reader.asset.duration.seconds
            self.videoInput!.requestMediaDataWhenReady(on: DispatchQueue(label: "com.mn.asset.video.export.queue")) {
                while let videoInput = self.videoInput, videoInput.isReadyForMoreMediaData {
                    let nextSampleBuffer = self.videoOutput?.copyNextSampleBuffer()
                    if self.status == .exporting, let sampleBuffer = nextSampleBuffer {
                        if videoInput.append(sampleBuffer) {
                            let time = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
                            self.update(progress: Float(time.seconds/duration))
                        } else {
                            reader.cancelReading()
                            videoInput.markAsFinished()
                            objc_sync_enter(self)
                            self.status = .failed
                            objc_sync_exit(self)
                            #if DEBUG
                            print("video write fail")
                            #endif
                        }
                    } else {
                        videoInput.markAsFinished()
                        group.leave()
                        break
                    }
                }
            }
        }
        
        // 音频数据转化
        if let _ = audioInput, let _ = audioOutput {
            group.enter()
            let duration = reader.asset.duration.seconds
            let shouldAudioCallback = (videoInput == nil || videoOutput == nil)
            self.audioInput!.requestMediaDataWhenReady(on: DispatchQueue(label: "com.mn.asset.audio.export.queue"), using: {
                while let audioInput = self.audioInput, audioInput.isReadyForMoreMediaData {
                    let nextSampleBuffer = self.audioOutput?.copyNextSampleBuffer()
                    if self.status == .exporting, let sampleBuffer = nextSampleBuffer {
                        if audioInput.append(sampleBuffer) {
                            if shouldAudioCallback {
                                let time = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
                                self.update(progress: Float(time.seconds/duration))
                            }
                        } else {
                            reader.cancelReading()
                            audioInput.markAsFinished()
                            objc_sync_enter(self)
                            self.status = .failed
                            objc_sync_exit(self)
                            #if DEBUG
                            print("video write fail")
                            #endif
                        }
                    } else {
                        audioInput.markAsFinished()
                        group.leave()
                        break
                    }
                }
            })
        }
        
        // 等待结果回调
        group.notify(queue: DispatchQueue(label: "com.mn.asset.finish.queue")) {
            if reader.status == .reading { reader.cancelReading() }
            writer.finishWriting {
                if let error = writer.error {
                    self.error = .writeError(.underlyingError(error))
                    if self.status == .exporting { self.status = .failed }
                }
                if FileManager.default.fileExists(atPath: outputURL.path) == false {
                    self.error = self.error ?? .custom(AVAssetExportSession.Status.failed.rawValue, "export failed")
                    if self.status != .cancelled { self.status = .failed }
                } else if self.status == .exporting {
                    self.status = .completed
                }
                if self.status == .cancelled || self.status == .failed {
                    self.error = self.error ?? (self.status == .cancelled ? .exportError(.cancelled) : .custom(AVAssetExportSession.Status.failed.rawValue, "export failed"))
                    try? FileManager.default.removeItem(at: outputURL)
                }
                if self.status == .completed, self.progress < 1.0 {
                    self.update(progress: 1.0)
                }
                self.audioInput = nil
                self.videoInput = nil
                self.audioOutput = nil
                self.videoOutput = nil
                self.completionHandler?(self.status, self.error)
            }
        }
    }
    
    private func finish(error: AVError?) {
        self.error = error
        status = .failed
        completionHandler?(.failed, error)
    }
    
    private func update(progress: Float) {
        self.progress = progress
        progressHandler?(progress)
    }
    
    // MARK: - cancel
    func cancel() {
        guard status == .exporting else { return }
        status = .cancelled
    }
}

// MARK: - convenience
extension MNAssetExporter {
    
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
extension MNAssetExporter {
    
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
