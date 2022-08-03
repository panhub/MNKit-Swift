//
//  MNScanner.swift
//  anhe
//
//  Created by 冯盼 on 2022/3/28.
//  扫描方案

import UIKit
import Foundation
import CoreMedia
import AVFoundation
import CoreFoundation

@objc protocol MNScannerDelegate: NSObjectProtocol {
    func scanner(_ scanner: MNScanner, didReadMetadata result: String) -> Void
    @objc optional func scannerDidStartRunning(_ scanner: MNScanner) -> Void
    @objc optional func scannerDidStopRunning(_ scanner: MNScanner) -> Void
    @objc optional func scannerDidChangeTorchScene(_ scanner: MNScanner) -> Void
    @objc optional func scanner(_ scanner: MNScanner, didUpdateBrightness value: Float) -> Void
    @objc optional func scanner(_ scanner: MNScanner, didFail error: Error) -> Void
}

class MNScanner: NSObject {
    /// 事件代理
    weak var delegate: MNScannerDelegate?
    /// 串行队列
    let queue: DispatchQueue = DispatchQueue(label: "com.mn.scanner.queue")
    /// 设备
    private var device: AVCaptureDevice?
    /// 输出
    private var output: AVCaptureMetadataOutput?
    /// 显示层
    private var layer: AVCaptureVideoPreviewLayer?
    /// 视频输出
    private var videoInput: AVCaptureDeviceInput?
    /// 显示的视图
    private weak var preview: UIView?
    /// 设置显示的视图层
    weak var view: UIView? {
        get { preview }
        set {
            preview = newValue
            DispatchQueue.main.async { [weak self] in
                guard let view = self?.preview, let layer = self?.layer else { return }
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.removeFromSuperlayer()
                layer.frame = view.bounds
                view.layer.insertSublayer(layer, at: 0)
                CATransaction.commit()
            }
        }
    }
    /// 显示的区域
    private var prerect: CGRect = .zero
    /// 设置扫描区域
    var rect: CGRect {
        get { prerect }
        set {
            prerect = newValue
            DispatchQueue.main.async { [weak self] in
                guard let view = self?.preview, let output = self?.output else { return }
                guard newValue != .zero else {
                    output.rectOfInterest = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
                    return
                }
                let width = view.frame.width
                let height = view.frame.height
                guard width > 0.0, height > 0.0 else { return }
                let x = newValue.origin.y/height
                let y = newValue.origin.x/width
                let w = newValue.height/height
                let h = newValue.width/width
                output.rectOfInterest = CGRect(x: x, y: y, width: w, height: h)
            }
        }
    }
    /// 屏幕捕捉会话
    private var session: AVCaptureSession!
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(sessionDidStartRunning(_:)), name: .AVCaptureSessionDidStartRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionDidStopRunning(_:)), name: .AVCaptureSessionDidStopRunning, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 即将开始扫描
    func prepareRunning() {
        #if arch(i386) || arch(x86_64)
        #else
        MNAuthorization.requestCamera(using: queue) { [weak self] result in
            guard let self = self else { return }
            guard result else {
                self.fail(error: .notPermission(.cameraDenied))
                return
            }
            // 拍摄会话
            let session = AVCaptureSession()
            session.usesApplicationAudioSession = false
            if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            } else if session.canSetSessionPreset(.hd1920x1080) {
                session.sessionPreset = .hd1920x1080
            } else if session.canSetSessionPreset(.hd1280x720) {
                session.sessionPreset = .hd1280x720
            } else if session.canSetSessionPreset(.medium) {
                session.sessionPreset = .medium
            } else if session.canSetSessionPreset(.low) {
                session.sessionPreset = .low
            }
            self.session = session
            // 寻找设备
            for device in AVCaptureDevice.devices(for: .video) {
                guard device.position == .back else { continue }
                self.device = device
                break
            }
            guard let device = self.device else {
                self.fail(error: .deviceError(.notFound))
                return
            }
            // 输入
            var videoInput: AVCaptureDeviceInput!
            do {
                videoInput = try AVCaptureDeviceInput(device: device)
            } catch {
                self.fail(error: .deviceError(.cannotCreateVideoInput))
                return
            }
            guard self.session.canAddInput(videoInput) else {
                self.fail(error: .sessionError(.cannotAddVideoInput))
                return
            }
            self.session.addInput(videoInput)
            // 图像输出
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.mn.scanner.data.output"))
            guard self.session.canAddOutput(videoOutput) else {
                self.fail(error: .sessionError(.cannotAddVideoOutput))
                return
            }
            self.session.addOutput(videoOutput)
            // 数据输出
            let metadataOutput = AVCaptureMetadataOutput()
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "com.mn.scanner.metadata.output"))
            guard self.session.canAddOutput(metadataOutput) else {
                self.fail(error: .sessionError(.cannotAddVideoOutput))
                return
            }
            self.session.addOutput(metadataOutput)
            self.output = metadataOutput
            // 设置支持的编码格式(条形码和二维码兼容)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .code128]
            // 图像显示
            let layer = AVCaptureVideoPreviewLayer(session: self.session)
            layer.contentsScale = UIScreen.main.scale
            layer.videoGravity = .resizeAspectFill
            self.layer = layer
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.view = self.preview
                self.rect = self.prerect
                self.session.startRunning()
            }
        }
        #endif
    }
    
    /// 设备变化调整
    /// - Parameter handler: 设备回调
    private func performDeviceChange(handler: ((AVCaptureDevice?)->Void)?) {
        guard let device = videoInput?.device else {
            handler?(nil)
            return
        }
        do {
            try device.lockForConfiguration()
            handler?(device)
            device.unlockForConfiguration()
        } catch {
            handler?(nil)
        }
    }
    
    /// 错误回调
    /// - Parameter error: 错误信息
    private func fail(error: AVError) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scanner?(self, didFail: error)
        }
    }
}

// MARK: - Session
extension MNScanner {
    
    /// 是否开启了会话
    var isRunning: Bool {
        var flag: Bool = false
        queue.sync { [weak self] in
            guard let session = self?.session else { return }
            flag = session.isRunning
        }
        return flag
    }
    
    /// 开启扫描会话
    func startRunning() {
        queue.async { [weak self] in
            guard let session = self?.session, session.isRunning == false else { return }
            session.startRunning()
        }
    }
    
    /// 停止扫描会话
    func stopRunning() {
        queue.async { [weak self] in
            guard let session = self?.session, session.isRunning else { return }
            session.stopRunning()
        }
    }
}

// MARK: - Torch
extension MNScanner {
    
    var isTorching: Bool {
        guard let device = videoInput?.device, device.hasTorch else { return false }
        return device.torchMode == .on
    }
    
    func openTorch() {
        var isChangeTorch: Bool = false
        performDeviceChange { device in
            guard let device = device, device.hasTorch, device.torchMode != .on else { return }
            if device.isTorchModeSupported(.on) {
                isChangeTorch = true
                device.torchMode = .on
                //device.torchLevel = 0.5
            }
        }
        if isChangeTorch {
            delegate?.scannerDidChangeTorchScene?(self)
        }
    }
    
    func closeTorch() {
        var isChangeTorch: Bool = false
        performDeviceChange { device in
            guard let device = device, device.hasTorch, device.torchMode != .off else { return }
            if device.isTorchModeSupported(.off) {
                isChangeTorch = true
                device.torchMode = .off
            }
        }
        if isChangeTorch {
            delegate?.scannerDidChangeTorchScene?(self)
        }
    }
}

// MARK: - Focus
extension MNScanner {
    func update(focus point: CGPoint, completion completionHandler:((Bool)->Void)? = nil) {
        var result: Bool = false
        performDeviceChange { [weak self] device in
            guard let layer = self?.layer, let device = device, device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) else { return }
            device.focusPointOfInterest = layer.captureDevicePointConverted(fromLayerPoint: point)
            device.focusMode = .autoFocus
            result = true
        }
        completionHandler?(result)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension MNScanner: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0 else { return }
        for object in metadataObjects {
            guard let codeObject = object as? AVMetadataMachineReadableCodeObject else { continue }
            guard let string = codeObject.stringValue, string.count > 0 else { continue }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.scanner(self, didReadMetadata: string)
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension MNScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let metadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) as? [String:Any] else { return }
        guard let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String:Any] else { return }
        guard let brightness = exif[kCGImagePropertyExifBrightnessValue as String] as? Float else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scanner?(self, didUpdateBrightness: brightness)
        }
    }
}

// MARK: - 解析图片二维码信息
extension MNScanner {
    
    /// 识别图片二维码
    /// - Parameters:
    ///   - image: 指定图片
    ///   - completionHandler: 识别结果回调
    static func readImageMetadata(_ image: UIImage, completion completionHandler: @escaping ((String?)->Void)) {
        DispatchQueue.global().async {
            guard let cgImage = image.cgImage, let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]) else {
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
                return
            }
            let features = detector.features(in: CIImage(cgImage: cgImage))
            guard features.count > 0 else {
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
                return
            }
            var result: String?
            for feature in features {
                guard let codeFeature = feature as? CIQRCodeFeature else { continue }
                guard let msg = codeFeature.messageString, msg.count > 0 else { continue }
                result = msg
                break
            }
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }
}

// MARK: - Notification
private extension MNScanner {
    
    @objc func sessionDidStartRunning(_ notify: Notification) {
        guard let session = notify.object as? AVCaptureSession, session == self.session else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scannerDidStartRunning?(self)
        }
    }
    
    @objc func sessionDidStopRunning(_ notify: Notification) {
        guard let session = notify.object as? AVCaptureSession, session == self.session else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scannerDidStopRunning?(self)
        }
    }
}
