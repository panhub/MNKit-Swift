//
//  MNPHError.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/20.
//

import Foundation

let MNPHErrorFileDoesNotExist = NSURLErrorFileDoesNotExist

enum MNPHError: Swift.Error {
    
    enum LivePhotoErrorReason {
        case fileNotExist
        case requestFailed
        case underlyingError(Error)
    }
    
    enum AssetDeleteErrorReason {
        case unknown
        case isEmpty
        case underlyingError(Error)
    }
    
    enum AssetWriteErrorReason {
        case unknown
        case underlyingError(Error)
    }
    
    //  LivePhoto导出/合成失败
    case livePhotoError(LivePhotoErrorReason)
    // 删除系统媒体时错误
    case deleteError(AssetDeleteErrorReason)
    // 保存媒体文件时错误
    case writeError(AssetWriteErrorReason)
}

extension Swift.Error {
    var phError: MNPHError? { self as? MNPHError }
}
