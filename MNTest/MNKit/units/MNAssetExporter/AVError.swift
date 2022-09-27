//
//  AVError.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/8.
//  错误信息

import Foundation
import AVFoundation


public let AVErrorUnknown: Int = -133303

enum AVError: Swift.Error {
    
    enum URLErrorReason {
        case badUrl
        case cannotCreateFile
        case cannotCreateDirectory(String)
    }
    
    enum TrackErrorReason {
        case notFound
        case notExists(AVMediaType)
        case cannotInsert(AVMediaType)
        case outputRectIsZero
    }
    
    enum AssetErrorReason {
        case notFound
    }
    
    enum ReadErrorReason {
        case cannotReading
        case cannotCreateReader
        case cannotAddVoidOutput
        case cannotAddAudioOutput
        case underlyingError(Error)
    }
    
    enum WriteErrorReason {
        case cannotWriting
        case cannotCreateWriter
        case cannotAddVoidInput
        case cannotAddAudioInput
        case cannotAppendAudioBuffer
        case cannotAppendVideoBuffer
        case underlyingError(Error)
    }
    
    enum ExportFailureReason {
        case unknown
        case cancelled
        case unsupported
        case underlyingError(Error)
    }
    
    enum RecordFailureReason {
        case cannotConvertCamera
    }
    
    enum AuthorizationFailureReason {
        case cameraDenied
        case microphoneDenied
    }
    
    enum SessionErrorReason {
        case notRunning
        case categoryNotActive(AVAudioSession.Category)
        case unsupportedPreset(AVCaptureSession.Preset)
        case cannotAddAudioInput
        case cannotAddVideoInput
        case cannotAddAudioOutput
        case cannotAddVideoOutput
        case cannotAddImageOutput
        case cannotAddPhotoOutput
    }
    
    enum CaptureFailureReason {
        case busying
        case photoOutputNotFound
        case unsupportedPhotoFormat
        case cannotCapturePhoto
        case cannotCaptureLivePhoto
        case underlyingError(Error)
    }
    
    enum DeviceErrorReason {
        case notFound
        case torchNotFound
        case flashNotFound
        case cannotCreateAudioInput
        case cannotCreateVideoInput
        case unsupportedFlashMode(AVCaptureDevice.FlashMode)
        case unsupportedTorchMode(AVCaptureDevice.TorchMode)
    }
    
    enum PlayErrorReason {
        case playFailed
        case notActive(AVAudioSession.Category)
        case statusError(AVPlayer.Status)
        case custom(Int, String)
        case underlyingError(Error)
    }
    
    case urlError(URLErrorReason)
    case trackError(TrackErrorReason)
    case exportError(ExportFailureReason)
    case assetError(AssetErrorReason)
    case readError(ReadErrorReason)
    case writeError(WriteErrorReason)
    case recordError(RecordFailureReason)
    case notPermission(AuthorizationFailureReason)
    case sessionError(SessionErrorReason)
    case captureError(CaptureFailureReason)
    case deviceError(DeviceErrorReason)
    case playError(PlayErrorReason)
    case custom(Int, String)
}

extension Swift.Error {
    
    /// 转化错误
    var avError: AVError? { self as? AVError }
}

extension AVError {
    
    var errMsg: String {
        switch self {
        case .urlError(let reason):
            return reason.errMsg
        case .trackError(let reason):
            return reason.errMsg
        case .exportError(let reason):
            return reason.errMsg
        case .assetError(let reason):
            return reason.errMsg
        case .readError(let reason):
            return reason.errMsg
        case .writeError(let reason):
            return reason.errMsg
        case .recordError(let reason):
            return reason.errMsg
        case .notPermission(let reason):
            return reason.errMsg
        case .sessionError(let reason):
            return reason.errMsg
        case .captureError(let reason):
            return reason.errMsg
        case .deviceError(let reason):
            return reason.errMsg
        case .playError(let reason):
            return reason.errMsg
        case .custom(_, let msg):
            return msg
        }
    }
    
    var isAuthorizationError: Bool {
        switch self {
        case .notPermission(_):
            return true
        default:
            return false
        }
    }
}

extension AVError.URLErrorReason {
    
    var errMsg: String {
        switch self {
        case .badUrl:
            return "文件路径不可用"
        case .cannotCreateFile:
            return "无法创建文件"
        case .cannotCreateDirectory(_):
            return "无法创建文件夹"
        }
    }
}

extension AVError.TrackErrorReason {
    
    var errMsg: String {
        switch self {
        case .notFound:
            return "素材不存在"
        case .notExists(let type):
            return "\(type == .video ? "视频" : "音频")素材不存在"
        case .cannotInsert(let type):
            return "插入\(type == .video ? "视频" : "音频")素材失败"
        case .outputRectIsZero:
            return "输出尺寸为空"
        }
    }
}

extension AVError.AssetErrorReason {
    
    var errMsg: String {
        switch self {
        case .notFound:
            return "资源不存在"
        }
    }
}

extension AVError.ReadErrorReason {
    
    var errMsg: String {
        switch self {
        case .cannotCreateReader:
            return "无法读取文件"
        case .cannotAddVoidOutput:
            return "视频读取失败"
        case .cannotAddAudioOutput:
            return "音频读取失败"
        case .cannotReading:
            return "文件读取失败"
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
}

extension AVError.WriteErrorReason {
    
    var errMsg: String {
        switch self {
        case .cannotCreateWriter:
            return "无法写入文件"
        case .cannotAddVoidInput:
            return "视频写入失败"
        case .cannotAddAudioInput:
            return "音频写入失败"
        case .cannotWriting:
            return "无法写入失败"
        case .cannotAppendAudioBuffer:
            return "追加音频数据失败"
        case .cannotAppendVideoBuffer:
            return "追加视频数据失败"
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
}

extension AVError.ExportFailureReason {
    
    var errMsg: String {
        switch self {
        case .unknown:
            return "发生未知错误"
        case .cancelled:
            return "已取消操作"
        case .unsupported:
            return "不支持此操作"
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
}

extension AVError.RecordFailureReason {
    
    var errMsg: String {
        switch self {
        case .cannotConvertCamera:
            return "切换摄像头失败"
        }
    }
}

extension AVError.AuthorizationFailureReason {
    
    var errMsg: String {
        switch self {
        case .cameraDenied:
            return "访问摄像头被拒绝"
        case .microphoneDenied:
            return "访问麦克风被拒绝"
        }
    }
}

extension AVError.SessionErrorReason {
    
    var errMsg: String {
        switch self {
        case .notRunning:
            return "捕获未开启"
        case .categoryNotActive(let category):
            return "会话类别设置失败:\(category.rawValue)"
        case .unsupportedPreset(let sessionPreset):
            return "不支持会话类型:\(sessionPreset.rawValue)"
        case .cannotAddAudioInput:
            return "无法添加设备"
        case .cannotAddVideoInput:
            return "无法添加设备"
        case .cannotAddAudioOutput:
            return "无法添加设备"
        case .cannotAddVideoOutput:
            return "无法添加设备"
        case .cannotAddImageOutput:
            return "无法拍摄照片"
        case .cannotAddPhotoOutput:
            return "无法拍摄照片"
        }
    }
}

extension AVError.CaptureFailureReason {
    
    var errMsg: String {
        switch self {
        case .busying:
            return "繁忙"
        case .photoOutputNotFound:
            return "照片配置错误"
        case .unsupportedPhotoFormat:
            return "不支持照片格式"
        case .cannotCapturePhoto:
            return "捕捉图像失败"
        case .cannotCaptureLivePhoto:
            return "捕捉LivePhoto失败"
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
}

extension AVError.DeviceErrorReason {
    
    var errMsg: String {
        switch self {
        case .notFound:
            return "未发现设备"
        case .flashNotFound:
            return "未发现闪光灯"
        case .torchNotFound:
            return "未发现手电筒"
        case .cannotCreateAudioInput:
            return "创建音频输出失败"
        case .cannotCreateVideoInput:
            return "创建视频输出失败"
        case .unsupportedFlashMode(let mode):
            return "\(mode == .on ? "开启" : "关闭")闪光灯失败"
        case .unsupportedTorchMode(let mode):
            return "\(mode == .on ? "开启" : "关闭")手电筒失败"
        }
    }
}

extension AVError.PlayErrorReason {
    
    var errMsg: String {
        switch self {
        case .playFailed:
            return "播放失败"
        case .notActive(_):
            return "设置会话模式失败"
        case .statusError(_):
            return "媒体文件解析错误"
        case .custom(_, let msg):
            return msg
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
}


