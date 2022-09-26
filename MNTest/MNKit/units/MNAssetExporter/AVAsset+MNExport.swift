//
//  AVURLAsset+MNExport.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/30.
//  

import Foundation
import AVFoundation

extension AVURLAsset {
    
    convenience init(mediaOfURL url: URL) {
        self.init(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: url.isFileURL])
    }
    
    convenience init?(mediaAtPath path: String) {
        guard path.isEmpty == false else { return nil }
        let url = FileManager.default.fileExists(atPath: path) ? URL(fileURLWithPath: path) : URL(string: path)
        guard let _ = url else { return nil }
        self.init(mediaOfURL: url!)
    }
}

extension AVAsset {
    /**时长**/
    var seconds: TimeInterval {
        CMTimeGetSeconds(duration)
    }
    /***/
    static func asset(mediaAtPath path: String) -> AVAsset? {
        return AVURLAsset(mediaAtPath: path)
    }

    static func asset(mediaOfURL url: URL) -> AVAsset? {
        return AVURLAsset(mediaOfURL: url)
    }
    
    func track(mediaType: AVMediaType) -> AVAssetTrack? {
        let tracks = tracks(withMediaType: mediaType)
        guard tracks.count > 0 else { return nil }
        return tracks.first
    }
    
    static func track(mediaAtPath path: String, mediaType type: AVMediaType) -> AVAssetTrack? {
        guard let asset = AVAsset.asset(mediaAtPath: path) else { return nil }
        return asset.track(mediaType: type)
    }
    
    static func track(mediaOfURL url: URL, mediaType type: AVMediaType) -> AVAssetTrack? {
        guard let asset = AVAsset.asset(mediaOfURL: url) else { return nil }
        return asset.track(mediaType: type)
    }
    
    func timeRange(fromProgress from: Double, toProgress to: Double) -> CMTimeRange {
        guard from >= 0.0, to <= 1.0, to > from else { return .zero }
        let start = CMTimeMultiplyByFloat64(duration, multiplier: Float64(from))
        let duration = CMTimeMultiplyByFloat64(duration, multiplier: Float64(to - from))
        return CMTimeRange(start: start, duration: duration)
    }
    
    func timeRange(fromSeconds from: Double, toSeconds to: Double) -> CMTimeRange {
        let time: CMTime = duration
        let duration: Double = Double(CMTimeGetSeconds(time))
        let begin = min(duration, max(0.0, from))
        let end = min(duration, max(begin, to))
        guard duration > 0.0, end > from else { return .zero }
        return CMTimeRange(start: CMTime(seconds: begin, preferredTimescale: time.timescale), duration: CMTime(seconds: end - begin, preferredTimescale: time.timescale))
    }
}
