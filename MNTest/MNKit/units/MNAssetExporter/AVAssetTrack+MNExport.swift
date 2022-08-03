//
//  AVAssetTrack+MNExport.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/30.
//

import Foundation
import AVFoundation

extension AVAssetTrack {
    
    var naturalSizeOfVideo: CGSize {
        guard mediaType == .video else { return .zero }
        var naturalSize = naturalSize.applying(preferredTransform)
        naturalSize.width = abs(naturalSize.width)
        naturalSize.height = abs(naturalSize.height)
        return naturalSize
    }
    
    var preferredTransformOfVideo: CGAffineTransform {
        guard mediaType == .video else { return .identity }
        var angle: Double = 0.0
        let transform = preferredTransform
        if transform.b == 1, transform.c == -1 {
            angle = .pi/2.0
        } else if transform.a == -1, transform.d == -1 {
            angle = .pi
        } else if transform.b == -1, transform.c == 1 {
            angle = .pi/2.0*3.0
        }
        return CGAffineTransform(rotationAngle: angle)
    }
    
    func transform(withRenderSize renderSize: CGSize) -> CGAffineTransform {
        let naturalSize = naturalSizeOfVideo
        guard naturalSize != .zero else { return .identity }
        return transform(withRect: CGRect(x: 0.0, y: 0.0, width: naturalSize.width, height: naturalSize.height), renderSize: renderSize)
    }
    
    func transform(withRect outputRect: CGRect, renderSize: CGSize) -> CGAffineTransform {
        let naturalSize = naturalSizeOfVideo
        guard naturalSize != .zero else { return .identity }
        var angle: Double = 0.0
        var x = outputRect.minX
        var y = outputRect.minY
        let xScale = renderSize.width/outputRect.width
        let yScale = renderSize.height/outputRect.height
        let transform = preferredTransform
        if transform.b == 1, transform.c == -1 {
            angle = .pi/2.0;
            x = naturalSize.width - x
            y = -y
        } else if transform.a == -1, transform.d == -1 {
            angle = .pi
            x = naturalSize.width - x
            y = naturalSize.height - y
        } else if transform.b == -1, transform.c == 1 {
            angle = .pi/2.0*3.0
            x = -x
            y = naturalSize.height - y
        } else {
            angle = 0.0
            x = -x
            y = -y
        }
        var videoTransform = CGAffineTransform(rotationAngle: angle)
        videoTransform = videoTransform.concatenating(CGAffineTransform(scaleX: xScale, y: yScale))
        videoTransform = videoTransform.concatenating(CGAffineTransform(translationX: x*xScale, y: y*yScale))
        return videoTransform
    }
}
