//
//  MNAssetExporter+MNMetadata.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/10.
//

import UIKit
import Foundation
import AVFoundation

struct MNFileType: Hashable, Equatable, RawRepresentable {
    let rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension MNFileType {
    static let mov: MNFileType = MNFileType(rawValue: "mov")
    static let m4a: MNFileType = MNFileType(rawValue: "m4a")
    static let m4v: MNFileType = MNFileType(rawValue: "m4v")
    static let mp3: MNFileType = MNFileType(rawValue: "mp3")
    static let mp4: MNFileType = MNFileType(rawValue: "mp4")
}

struct MNMetadataKey: Hashable, Equatable, RawRepresentable {
    let rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension MNMetadataKey {
    static let title: MNMetadataKey = MNMetadataKey(rawValue: "title")
    static let artist: MNMetadataKey = MNMetadataKey(rawValue: "artist")
    static let artwork: MNMetadataKey = MNMetadataKey(rawValue: "artwork")
    static let type: MNMetadataKey = MNMetadataKey(rawValue: "type")
    static let author: MNMetadataKey = MNMetadataKey(rawValue: "author")
    static let filePath: MNMetadataKey = MNMetadataKey(rawValue: "filePath")
    static let thumbnail: MNMetadataKey = MNMetadataKey(rawValue: "thumbnail")
    static let duration: MNMetadataKey = MNMetadataKey(rawValue: "duration")
    static let creationDate: MNMetadataKey = MNMetadataKey(rawValue: "creationDate")
    static let albumName: MNMetadataKey = MNMetadataKey(rawValue: "albumName")
    static let naturalSize: MNMetadataKey = MNMetadataKey(rawValue: "naturalSize")
}

extension MNAssetExporter {
    
    @objc static func duration(mediaAtPath path: String) -> TimeInterval {
        guard let asset = AVAsset.asset(mediaAtPath: path) else { return 0.0 }
        return asset.seconds
    }
    
    @objc static func naturalSize(videoAtPath path: String) -> CGSize {
        guard let videoTrack = AVAsset.track(mediaAtPath: path, mediaType: .video) else { return .zero }
        return videoTrack.naturalSizeOfVideo
    }
    
    @objc static func thumbnail(videoAtPath path: String, seconds: TimeInterval = 0.1, maximumSize: CGSize = .zero) -> UIImage? {
        guard let videoAsset = AVAsset.asset(mediaAtPath: path) else { return nil }
        let generator = AVAssetImageGenerator(asset: videoAsset)
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        generator.appliesPreferredTrackTransform = true
        if maximumSize != .zero { generator.maximumSize = maximumSize }
        let time = CMTimeMultiplyByFloat64(videoAsset.duration, multiplier: max(0.01, min(0.99, Float64(seconds)/CMTimeGetSeconds(videoAsset.duration))))
        //time.value = CMTimeValue(Double(time.timescale)*seconds)
        guard let cgImage = try?generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    @objc static func artwork(mediaAtPath path: String) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        guard let asset = AVAsset.asset(mediaAtPath: path) else { return nil }
        var artwork: UIImage?
        let formats = asset.availableMetadataFormats
        for format in formats {
            let metadataItems = asset.metadata(forFormat: format)
            guard metadataItems.count > 0 else { continue }
            var stop = false
            for metadataItem in metadataItems {
                guard let commonKey = metadataItem.commonKey, commonKey == .commonKeyArtwork else { continue }
                guard let data = metadataItem.value as? Data else { continue }
                artwork = UIImage(data: data)
                stop = true
            }
            if stop { break }
        }
        return artwork
    }
    
    @objc static func brief(mediaAtPath path: String) -> [AVMetadataKey:String] {
        guard FileManager.default.fileExists(atPath: path) else { return [:] }
        guard let asset = AVAsset.asset(mediaAtPath: path) else { return [:] }
        var result: [AVMetadataKey:String] = [AVMetadataKey:String]()
        let formats = asset.availableMetadataFormats
        for format in formats {
            let metadataItems = asset.metadata(forFormat: format)
            for metadataItem in metadataItems {
                guard let key = metadataItem.commonKey else { continue }
                let value = metadataItem.value
                if key == .commonKeyTitle {
                    if let data = value as? Data {
                        if let string = String(data: data, encoding: .utf8) {
                            result[.commonKeyTitle] = string
                        }
                    } else if let string = value as? String {
                        result[.commonKeyTitle] = string
                    }
                } else if key == .commonKeyArtist {
                    if let data = value as? Data {
                        if let string = String(data: data, encoding: .utf8) {
                            result[.commonKeyArtist] = string
                        }
                    } else if let string = value as? String {
                        result[.commonKeyArtist] = string
                    }
                } else if key == .commonKeyAuthor {
                    if let data = value as? Data {
                        if let string = String(data: data, encoding: .utf8) {
                            result[.commonKeyAuthor] = string
                        }
                    } else if let string = value as? String {
                        result[.commonKeyAuthor] = string
                    }
                } else if key == .commonKeyAlbumName {
                    if let data = value as? Data {
                        if let string = String(data: data, encoding: .utf8) {
                            result[.commonKeyAlbumName] = string
                        }
                    } else if let string = value as? String {
                        result[.commonKeyAlbumName] = string
                    }
                } else if key == .commonKeyCreationDate {
                    if let data = value as? Data {
                        if let string = String(data: data, encoding: .utf8) {
                            result[.commonKeyCreationDate] = string
                        }
                    } else if let string = value as? String {
                        result[.commonKeyCreationDate] = string
                    } else if let date = value as? Date {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        formatter.timeZone = TimeZone(secondsFromGMT: 3600*8)
                        result[.commonKeyCreationDate] = formatter.string(from: date)
                    }
                }
            }
        }
        return result
    }
}
