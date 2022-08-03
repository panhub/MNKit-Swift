//
//  MNAuthorization.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/12.
//  获取权限

import UIKit
import Foundation
import Photos.PHPhotoLibrary
import AVFoundation
import AppTrackingTransparency
import AdSupport

typealias MNAuthorizationResultHandler = (Bool)->Void

class MNAuthorization {
    
    /**请求相册权限*/
    static func requestAlbum(using queue: DispatchQueue = DispatchQueue.main, statusHandler: MNAuthorizationResultHandler?) {
        func callback(_ status: PHAuthorizationStatus) {
            queue.async {
                if #available(iOS 14, *) {
                    statusHandler?(status == .authorized || status == .limited)
                } else {
                    statusHandler?(status == .authorized)
                }
            }
        }
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            queue.async {
                statusHandler?(false)
            }
            return
        }
        var status: PHAuthorizationStatus = .denied
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
        if status == .notDetermined {
            let authorizationHandler: (PHAuthorizationStatus)->Void = { s in
                callback(s)
            }
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: authorizationHandler)
            } else {
                PHPhotoLibrary.requestAuthorization(authorizationHandler)
            }
        } else {
            callback(status)
        }
    }

    /**请求相机权限*/
    static func requestCamera(using queue: DispatchQueue = DispatchQueue.main, statusHandler: MNAuthorizationResultHandler?) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { result in
                queue.async {
                    statusHandler?(result)
                }
            }
        } else {
            queue.async {
                statusHandler?(status == .authorized)
            }
        }
    }
    
    /**请求麦克风权限 AVCaptureDevice*/
    static func requestMicrophone(using queue: DispatchQueue = DispatchQueue.main, statusHandler: MNAuthorizationResultHandler?) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { result in
                queue.async {
                    statusHandler?(result)
                }
            }
        } else {
            queue.async {
                statusHandler?(status == .authorized)
            }
        }
    }
    
    /**请求麦克风权限 AVAudioSession*/
    static func requestMicrophonePermission(using queue: DispatchQueue = DispatchQueue.main, statusHandler: MNAuthorizationResultHandler?) {
        let permisson = AVAudioSession.sharedInstance().recordPermission
        if permisson == .undetermined {
            AVAudioSession.sharedInstance().requestRecordPermission { result in
                queue.async {
                    statusHandler?(result)
                }
            }
        } else {
            queue.async {
                statusHandler?(permisson == .granted)
            }
        }
    }
    
    /**请求IDFA采集权限*/
    static func requestTracking(using queue: DispatchQueue = DispatchQueue.main, statusHandler: MNAuthorizationResultHandler?) {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { result in
                    queue.async {
                        statusHandler?(result == .authorized)
                    }
                }
            } else {
                queue.async {
                    statusHandler?(status == .authorized)
                }
            }
        } else {
            // Fallback on earlier versions
            queue.async {
                statusHandler?(ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
            }
        }
    }
}
