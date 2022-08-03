//
//  AVCaptureDevice+MNFormat.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/12.
//

import Foundation
import AVFoundation
import CoreMedia

extension AVCaptureDevice {
    
    var maxFrameRateRange: AVFrameRateRange? {
        var frameRateRange: AVFrameRateRange?
        for format in formats {
            let codecType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
            if codecType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
                let frameRateRanges = format.videoSupportedFrameRateRanges
                for range in frameRateRanges {
                    if frameRateRange == nil || range.maxFrameRate > frameRateRange!.maxFrameRate {
                        frameRateRange = range
                    }
                }
            }
        }
        return frameRateRange
    }
    
    var maxFrameRateFormat: AVCaptureDevice.Format? {
        var frameRateRange: AVFrameRateRange?
        var frameRateFormat: AVCaptureDevice.Format?
        for format in formats {
            let codecType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
            if codecType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
                let frameRateRanges = format.videoSupportedFrameRateRanges
                for range in frameRateRanges {
                    if frameRateRange == nil || range.maxFrameRate > frameRateRange!.maxFrameRate {
                        frameRateRange = range
                        frameRateFormat = format
                    }
                }
            }
        }
        return frameRateFormat
    }
    
    var isHighFrameRate: Bool {
        guard let frameRateRange = maxFrameRateRange else { return false }
        return frameRateRange.maxFrameRate >= 30.0
    }
}
