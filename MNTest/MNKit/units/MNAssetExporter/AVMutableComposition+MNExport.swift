//
//  AVMutableComposition+MNExport.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/30.
// 

import Foundation
import AVFoundation

// MARK: - Track
extension AVMutableComposition {
    
    func composition(mediaType: AVMediaType) -> AVMutableCompositionTrack? {
        let tracks = tracks(withMediaType: mediaType)
        guard tracks.count > 0 else {
            return addMutableTrack(withMediaType: mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        return tracks.first
    }
    
    func removeTrack(mediaType: AVMediaType) {
        for track in tracks(withMediaType: mediaType) {
            removeTrack(track)
        }
    }
    
    func removeAllTrack() {
        for type in [AVMediaType.video, AVMediaType.audio, AVMediaType.text, AVMediaType.subtitle] {
            removeTrack(mediaType: type)
        }
    }
}

// MARK: - append
extension AVMutableComposition {
    
    func append(assetOfURL url: URL) -> Bool {
        guard let asset = AVAsset.asset(mediaOfURL: url) else { return false }
        return append(asset: asset)
    }
    
    func append(asset: AVAsset) -> Bool {
        if let videoTrack = asset.track(mediaType: .video), append(track: videoTrack) == false { return false }
        if let audioTrack = asset.track(mediaType: .audio), append(track: audioTrack) == false { return false }
        return true
    }
    
    func append(assetOfURL url: URL, mediaType: AVMediaType) -> Bool {
        guard let asset = AVAsset.asset(mediaOfURL: url), let track = asset.track(mediaType: mediaType) else { return false }
        return append(track: track)
    }
    
    func append(track: AVAssetTrack) -> Bool {
        guard CMTIMERANGE_IS_VALID(track.timeRange) else { return false }
        if track.mediaType == .video {
            // 视频轨道
            guard let videoTrack = composition(mediaType: .video) else { return false }
            let time: CMTime = CMTIMERANGE_IS_VALID(videoTrack.timeRange) ? videoTrack.timeRange.duration : .zero
            do {
                try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: track.timeRange.duration), of: track, at: time)
            } catch {
#if DEBUG
                print(error)
#endif
                return false
            }
            return true
        } else if track.mediaType == .audio {
            // 音频轨道
            guard let audioTrack = composition(mediaType: .audio) else { return false }
            let time: CMTime = CMTIMERANGE_IS_VALID(audioTrack.timeRange) ? audioTrack.timeRange.duration : .zero
            do {
                try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: track.timeRange.duration), of: track, at: time)
            } catch  {
#if DEBUG
                print(error)
#endif
                return false
            }
            return true
        }
        return false
    }
}
