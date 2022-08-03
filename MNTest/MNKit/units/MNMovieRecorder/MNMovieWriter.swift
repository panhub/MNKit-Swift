//
//  MNMovieWriter.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/12.
//  视频写入

import Foundation
import ObjectiveC
import AVFoundation
import CoreMedia.CMSampleBuffer

@objc protocol MNMovieWriteDelegate: NSObjectProtocol {
    @objc optional func movieWriter(didStartWriting writer: MNMovieWriter) -> Void
    @objc optional func movieWriter(didFinishWriting writer: MNMovieWriter) -> Void
    @objc optional func movieWriter(didCancelWriting writer: MNMovieWriter) -> Void
    @objc optional func movieWriter(_ writer: MNMovieWriter, didFailWithError error: Error?) -> Void
}

class MNMovieWriter: NSObject {
    
    /**状态**/
    private enum Status: Int {
        case idle, prepare, locked, writing, finish, cancelled, failed
    }
    
    /**视频文件路径**/
    var url: URL!
    /**帧率**/
    var frameRate: Int = 30
    /**视频旋转角度**/
    var transform: CGAffineTransform = .identity
    /**是否在写入**/
    private var isWriting: Bool {
        var flag: Bool = false
        objc_sync_enter(self)
        flag = status == .writing
        objc_sync_exit(self)
        return flag
    }
    /**当前状态**/
    private var status: Status = .idle
    /**内容写入者**/
    private var writer: AVAssetWriter!
    /**视频追加**/
    private var videoInput: AVAssetWriterInput!
    /**音频追加**/
    private var audioInput: AVAssetWriterInput!
    /**事件代理**/
    weak var delegate: MNMovieWriteDelegate?
    
    func startWriting() {
        if status == .prepare {
            #if DEBUG
            print("⚠️⚠️⚠️Already prepared, cannot prepare again!⚠️⚠️⚠️")
            #endif
            return
        }
        if status == .writing {
            #if DEBUG
            print("⚠️⚠️⚠️Moive is writing!⚠️⚠️⚠️")
            #endif
            return
        }
        guard let url = url, url.isFileURL else {
            update(status: .failed, error: .urlError(.badUrl))
            return
        }
        // 创建文件夹
        try? FileManager.default.removeItem(at: url)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            update(status: .failed, error: .urlError(.cannotCreateDirectory(url.deletingLastPathComponent().path)))
            return
        }
        var writer: AVAssetWriter?
        do {
            writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        } catch  {
            update(status: .failed, error: .writeError(.cannotCreateWriter))
            return
        }
        self.writer = writer
        update(status: .prepare, error: nil)
    }
    
    func finishWriting() {
        guard status == .writing else { return }
        update(status: .locked, error: nil)
        writer.finishWriting { [weak self] in
            guard let self = self else { return }
            if let error = self.writer.error {
                self.update(status: .failed, error: .writeError(.underlyingError(error)))
            } else {
                self.update(status: .finish, error: nil)
            }
        }
    }
    
    func cancelWriting() {
        guard status == .writing else { return }
        update(status: .locked, error: nil)
        writer.cancelWriting()
        update(status: .cancelled, error: nil)
    }
    
    private func update(status: Status, error: AVError?) {
        var shouldNotifyDelegate: Bool = false
        objc_sync_enter(self)
        if status != self.status {
            self.status = status
            if status.rawValue >= Status.writing.rawValue {
                shouldNotifyDelegate = true
                if status.rawValue >= Status.finish.rawValue {
                    writer = nil
                    videoInput = nil
                    audioInput = nil
                    if status.rawValue >= Status.cancelled.rawValue, let url = url {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
            }
        }
        objc_sync_exit(self)
        guard shouldNotifyDelegate else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.status == .writing {
                self.delegate?.movieWriter?(didStartWriting: self)
            } else if self.status == .finish {
                self.delegate?.movieWriter?(didFinishWriting: self)
            } else if self.status == .cancelled {
                self.delegate?.movieWriter?(didCancelWriting: self)
            } else if self.status == .failed {
                self.delegate?.movieWriter?(self, didFailWithError: error)
            }
        }
    }
}

// MARK: - Sample Buffer
extension MNMovieWriter {
    
    func append(sampleBuffer: CMSampleBuffer?, mediaType: AVMediaType) {
        guard let buffer = sampleBuffer else { return }
        autoreleasepool {
            
            guard self.status == .prepare || self.status == .writing else { return }
            
            if mediaType == .audio {
                if audioInput == nil, shouldWriteAudio(sourceFormatDescription: CMSampleBufferGetFormatDescription(buffer)) == false {
                    update(status: .failed, error: .writeError(.cannotAddAudioInput))
                }
                if let _ = audioInput, let _ = videoInput, appendAudio(sampleBuffer: buffer) == false {
                    update(status: .failed, error: .writeError(.cannotAppendAudioBuffer))
                }
            } else if mediaType == .video {
                if videoInput == nil, shouldWriteVideo(sourceFormatDescription: CMSampleBufferGetFormatDescription(buffer)) == false {
                    update(status: .failed, error: .writeError(.cannotAddVoidInput))
                }
                if let _ = audioInput, let _ = videoInput, appendVideo(sampleBuffer: buffer) == false {
                    update(status: .failed, error: .writeError(.cannotAppendVideoBuffer))
                }
            }
        }
        
        if status == .prepare, let writer = writer, writer.status == .writing {
            update(status: .writing, error: nil)
        }
    }
    
    private func shouldWriteVideo(sourceFormatDescription formatDescription: CMFormatDescription?) -> Bool {
        guard let description = formatDescription else { return false }
        let dimensions = CMVideoFormatDescriptionGetDimensions(description)
        let numPixels = dimensions.width*dimensions.height
        let bitsPerPixel: Float = numPixels < (640*480) ? 4.05 : 10.1;
        let profileLevel: String = ProcessInfo.processInfo.processorCount <= 1 ? AVVideoProfileLevelH264MainAutoLevel : AVVideoProfileLevelH264HighAutoLevel
        let compression: [String:Any] = [AVVideoAverageBitRateKey: Float(numPixels)*bitsPerPixel, AVVideoExpectedSourceFrameRateKey: frameRate, AVVideoMaxKeyFrameIntervalKey:frameRate, AVVideoProfileLevelKey:profileLevel]
        var settings: [String:Any] = [AVVideoWidthKey:dimensions.width, AVVideoHeightKey:dimensions.height, AVVideoCompressionPropertiesKey:compression]
        if #available(iOS 11.0, *) {
            settings[AVVideoCodecKey] = AVVideoCodecType.h264
        } else {
            settings[AVVideoCodecKey] = AVVideoCodecH264
        }
        guard writer.canApply(outputSettings: settings, forMediaType: .video) else { return false }
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        videoInput.expectsMediaDataInRealTime = true
        videoInput.transform = transform
        guard writer.canAdd(videoInput) else { return false }
        writer.add(videoInput)
        self.videoInput = videoInput
        return true
    }
    
    private func appendVideo(sampleBuffer: CMSampleBuffer) -> Bool {
        if writer.status == .unknown {
            guard writer.startWriting() else { return false }
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }
        if writer.status == .writing {
            if videoInput.isReadyForMoreMediaData {
                return videoInput.append(sampleBuffer)
            }
            return true
        }
        return false
    }
    
    private func appendAudio(sampleBuffer: CMSampleBuffer) -> Bool {
        if writer.status == .unknown {
            guard writer.startWriting() else { return false }
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }
        if writer.status == .writing {
            if audioInput.isReadyForMoreMediaData {
                return audioInput.append(sampleBuffer)
            }
            return true
        }
        return false
    }
    
    private func shouldWriteAudio(sourceFormatDescription formatDescription: CMFormatDescription?) -> Bool {
        guard let description = formatDescription else { return false }
        guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(description) else { return false }
        var size: Int = 0
        guard let channelLayout = CMAudioFormatDescriptionGetChannelLayout(description, sizeOut: &size) else { return false }
        let layoutData: Data = size > 0 ? Data(bytes: channelLayout, count: size) : Data()
        let settings: [String:Any] = [AVFormatIDKey:kAudioFormatMPEG4AAC, AVSampleRateKey:basicDescription.pointee.mSampleRate, AVChannelLayoutKey:layoutData, AVNumberOfChannelsKey:basicDescription.pointee.mChannelsPerFrame]
        guard writer.canApply(outputSettings: settings, forMediaType: .audio) else { return false }
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        audioInput.expectsMediaDataInRealTime = true
        guard writer.canAdd(audioInput) else { return false }
        writer.add(audioInput)
        self.audioInput = audioInput
        return true
    }
}
