//
//  MNMovieRecorder.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/12.
//  视频录制

import UIKit
import ObjectiveC
import AVFoundation
import AudioToolbox

enum MovieGravityMode: Int {
    case resize, resizeAspect, resizeAspectFill
}

enum MovieSizeRatio: Int {
    case unknown, ratio9x16, ratio3x4
}

enum MovieDevicePosition: Int {
    case back, front
}

enum MovieOrientation: Int {
    case auto, portrait, landscape
}

@objc protocol MNMovieRecordDelegate: NSObjectProtocol {
    @objc optional func movieRecorder(didStartRunning recorder: MNMovieRecorder) -> Void
    @objc optional func movieRecorder(didStopRunning recorder: MNMovieRecorder) -> Void
    @objc optional func movieRecorder(didStartRecording recorder: MNMovieRecorder) -> Void
    @objc optional func movieRecorder(didFinishRecording recorder: MNMovieRecorder) -> Void
    @objc optional func movieRecorder(didCancelRecording recorder: MNMovieRecorder) -> Void
    @objc optional func movieRecorder(didChangeFlashScene recorder: MNMovieRecorder) -> Void
    @objc optional func movieRecorder(didChangeTorchScene recorder: MNMovieRecorder) -> Void
    @objc optional func movieRecorder(didChangeSessionPreset recorder: MNMovieRecorder, error: Error?) -> Void
    @objc optional func movieRecorder(shouldUsingFlash recorder: MNMovieRecorder) -> Bool
    @objc optional func movieRecorder(beginTakingPhoto recorder: MNMovieRecorder, isLivePhoto: Bool) -> Void
    @objc optional func movieRecorder(_ recorder: MNMovieRecorder, didTakingLiveStillImage photo: MNCapturePhoto) -> Void
    @objc optional func movieRecorder(_ recorder: MNMovieRecorder, didTakingPhoto photo: MNCapturePhoto?, error: Error?) -> Void
    @objc optional func movieRecorder(_ recorder: MNMovieRecorder, didFailWithError error: Error?) -> Void
}

class MNMovieRecorder: NSObject {
    
    /**状态*/
    private enum Status: Int {
        case idle, recording, finish, cancelled, failed
    }
    
    /**视频文件路径*/
    var url: URL!
    /**视频拉伸方式*/
    var resizeMode: MovieGravityMode = .resizeAspectFill
    /**摄像头方向*/
    var devicePosition: MovieDevicePosition = .back
    /**视频拉伸方式*/
    var movieOrientation: MovieOrientation = .auto
    /**是否使用麦克风*/
    var isUsingMicrophone: Bool = true
    /**视频帧率*/
    var frameRate: Int = 30
    /**事件代理*/
    weak var delegate: MNMovieRecordDelegate?
    /**静音拍照*/
    var isMuteTaking: Bool = false
    /// 标记初始化错误
    private var configureError: AVError?
    /**录制时长时长*/
    var duration: TimeInterval {
        guard let url = url, FileManager.default.fileExists(atPath: url.path) else { return 0.0 }
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
        return asset.duration.seconds
    }
    /**预设比率*/
    var presetSizeRatio: MovieSizeRatio {
        return sizeRatio(sessionPreset: session.sessionPreset)
    }
    /**当前状态*/
    private var status: Status = .idle
    /**图像展示视图*/
    private weak var preview: UIView?
    weak var outputView: UIView? {
        get { preview }
        set {
            preview = newValue
            guard configureError == nil, let _ = videoOutput, let _ = newValue else { return }
            let videoLayerGravity = videoLayerGravity
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let view = self.preview else { return }
                self.layer.removeFromSuperlayer()
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.layer.frame = view.bounds
                self.layer.videoGravity = videoLayerGravity
                view.layer.insertSublayer(self.layer, at: 0)
                CATransaction.commit()
            }
        }
    }
    /**预览*/
    private lazy var layer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    private var videoLayerGravity: AVLayerVideoGravity {
        switch resizeMode {
        case .resize:
            return .resize
        case .resizeAspect:
            return .resizeAspect
        case .resizeAspectFill:
            return .resizeAspectFill
        }
    }
    /**设备检测*/
    private let motior: MNDeviceMotior = MNDeviceMotior()
    /**视频写入者*/
    private let movieWriter: MNMovieWriter = MNMovieWriter()
    /**质量*/
    var sessionPreset: AVCaptureSession.Preset = .high
    private var livePhoto: MNCapturePhoto?
    private var videoInput: AVCaptureDeviceInput!
    private var audioInput: AVCaptureDeviceInput!
    private var photoOutput: AVCaptureOutput?
    private var videoOutput: AVCaptureVideoDataOutput!
    private var audioOutput: AVCaptureAudioDataOutput!
    private var lastSessionPreset: AVCaptureSession.Preset = .high
    private let photoQueue: DispatchQueue = DispatchQueue(label: "com.mn.capture.photo.queue")
    private let outputQueue: DispatchQueue = DispatchQueue(label: "com.mn.capture.output.queue")
    private let sessionQueue: DispatchQueue = DispatchQueue(label: "com.mn.capture.session.queue")
    /**会话*/
    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.usesApplicationAudioSession = true
        if (session.canSetSessionPreset(sessionPreset)) {
            session.sessionPreset = sessionPreset
        }
        sessionPreset = session.sessionPreset
        lastSessionPreset = session.sessionPreset
        return session
    }()
    
    override init() {
        super.init()
        movieWriter.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(startRunning(_:)), name: NSNotification.Name.AVCaptureSessionDidStartRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRunning(_:)), name: NSNotification.Name.AVCaptureSessionDidStopRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted(_:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded(_:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func sizeRatio(sessionPreset: AVCaptureSession.Preset?) -> MovieSizeRatio {
        guard let preset = sessionPreset else { return .unknown }
        if #available(iOS 9.0, *) {
            if preset == .hd4K3840x2160 {
                return .ratio9x16
            }
        }
        if preset == .inputPriority {
            return ProcessInfo.processInfo.processorCount <= 1 ? .ratio3x4 : .ratio9x16
        }
        if preset == .high || preset == .hd1920x1080 || preset == .hd1280x720 || preset == .iFrame1280x720 || preset == .iFrame960x540 {
            return .ratio9x16
        }
        return .ratio3x4
    }
    
    func device(position: MovieDevicePosition) -> AVCaptureDevice? {
        let devicePosition: AVCaptureDevice.Position = position == .front ? .front : .back
        var device: AVCaptureDevice?
        if #available(iOS 10.0, *) {
            // 默认广角摄像头
            device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition)
        } else {
            for result in AVCaptureDevice.devices(for: .video) {
                if result.position == devicePosition {
                    device = result
                    break
                }
            }
        }
        return device
    }
    
    private func update(status: Status, error: AVError?) {
        self.status = status
        var shouldNotifyDelegate: Bool = false
        if status.rawValue >= Status.recording.rawValue {
            shouldNotifyDelegate = true
            if status.rawValue >= Status.finish.rawValue {
                closeTorch()
            }
        }
        guard shouldNotifyDelegate else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if status == .recording {
                self.delegate?.movieRecorder?(didStartRecording: self)
            } else if status == .finish {
                self.delegate?.movieRecorder?(didFinishRecording: self)
            } else if status == .cancelled {
                self.delegate?.movieRecorder?(didCancelRecording: self)
            } else if status == .failed {
                self.delegate?.movieRecorder?(self, didFailWithError: error)
            }
        }
    }
    
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
}

// MARK: - Prepare
extension MNMovieRecorder {
    
    func prepareCapturing() {
        // 请求权限
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted == false {
                    self?.configureError = .notPermission(.cameraDenied)
                }
                self?.sessionQueue.resume()
            }
        default:
            configureError = .notPermission(.cameraDenied)
        }
        // 配置
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        if let error = configureError {
            update(status: .failed, error: error)
            return
        }
        session.beginConfiguration()
        do {
            try setupVideo()
            if isUsingMicrophone {
                try setupAudio()
            }
            try setupPhoto()
        } catch {
            session.commitConfiguration()
            if let avError = error.avError {
                self.configureError = avError
                update(status: .failed, error: avError)
            }
        }
        session.commitConfiguration()
        if session.isRunning == false {
            session.startRunning()
        }
        outputView = outputView
    }
}

// MARK: - Setup
extension MNMovieRecorder {
    
    func setupVideo() throws {
        // 获取设配
        guard let device = device(position: devicePosition) else {
            throw AVError.deviceError(.notFound)
        }
        // Input
        var videoInput: AVCaptureDeviceInput!
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch  {
            #if DEBUG
            print("setupVideo 'videoInput': \(error)")
            #endif
            throw AVError.deviceError(.cannotCreateVideoInput)
        }
        guard session.canAddInput(videoInput) else {
            throw AVError.sessionError(.cannotAddVideoInput)
        }
        session.addInput(videoInput)
        // 配置
        do {
            try device.lockForConfiguration()
            if device.isSmoothAutoFocusSupported {
                device.isSmoothAutoFocusEnabled = true
            }
            device.unlockForConfiguration()
        } catch {
            #if DEBUG
            print(error)
            #endif
        }
        // Output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        guard session.canAddOutput(videoOutput) else {
            throw AVError.sessionError(.cannotAddVideoOutput)
        }
        session.addOutput(videoOutput)
        
        if let connection = videoOutput.connection(with: .video), connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        
        self.videoInput = videoInput
        self.videoOutput = videoOutput
    }
    
    func setupAudio() throws {
        // 获取设配
        guard let device = AVCaptureDevice.default(for: .audio) else {
            throw AVError.deviceError(.notFound)
        }
        // Input
        var audioInput: AVCaptureDeviceInput!
        do {
            audioInput = try AVCaptureDeviceInput(device: device)
        } catch {
            #if DEBUG
            print("setupAudio 'audioInput': \(error)")
            #endif
            throw AVError.deviceError(.cannotCreateAudioInput)
        }
        guard session.canAddInput(audioInput) else {
            throw AVError.sessionError(.cannotAddAudioInput)
        }
        session.addInput(audioInput)
        
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: outputQueue)
        guard session.canAddOutput(audioOutput) else {
            throw AVError.sessionError(.cannotAddAudioOutput)
        }
        session.addOutput(audioOutput)
        
        self.audioInput = audioInput
        self.audioOutput = audioOutput
    }
    
    func setupPhoto() throws {
        if #available(iOS 10.0, *) {
            let photoOutput = AVCapturePhotoOutput()
            photoOutput.isHighResolutionCaptureEnabled = true
            if #available(iOS 13.0, *) {
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
            guard session.canAddOutput(photoOutput) else {
                throw AVError.sessionError(.cannotAddPhotoOutput)
            }
            session.addOutput(photoOutput)
            if photoOutput.isLivePhotoCaptureSupported {
                photoOutput.isLivePhotoCaptureEnabled = true
                photoOutput.isLivePhotoAutoTrimmingEnabled = true
            }
            if let videoInput = self.videoInput, videoInput.device.position == .front, let photoConnection = photoOutput.connection(with: .video), photoConnection.isVideoMirroringSupported {
                photoConnection.isVideoMirrored = true
            }
            self.photoOutput = photoOutput
        } else {
            let photoOutput = AVCaptureStillImageOutput()
            photoOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            guard session.canAddOutput(photoOutput) else {
                throw AVError.sessionError(.cannotAddImageOutput)
            }
            session.addOutput(photoOutput)
            if let videoInput = self.videoInput, videoInput.device.position == .front, let photoConnection = photoOutput.connection(with: .video), photoConnection.isVideoMirroringSupported {
                photoConnection.isVideoMirrored = true
            }
            self.photoOutput = photoOutput
        }
    }
}

// MARK: - Running
extension MNMovieRecorder {
    
    var isRunning: Bool {
        var isRunning: Bool = false
        if let _ = videoOutput {
            isRunning = session.isRunning
        }
        return isRunning
    }
    
    func startRunning() {
        guard let _ = videoOutput else { return }
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning == false {
                self.session.startRunning()
            }
        }
    }
    
    func stopRunning() {
        guard let _ = videoOutput else { return }
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

// MARK: - Notification
extension MNMovieRecorder {
    
    @objc func startRunning(_ notify: Notification) {
        guard let session = notify.object as? AVCaptureSession, session == self.session else { return }
        motior.start()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.movieRecorder?(didStartRunning: self)
        }
    }
    
    @objc func stopRunning(_ notify: Notification) {
        guard let session = notify.object as? AVCaptureSession, session == self.session else { return }
        motior.stop()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.movieRecorder?(didStopRunning: self)
        }
    }
    
    @objc func sessionWasInterrupted(_ notify: Notification) {
        guard let session = notify.object as? AVCaptureSession, session == self.session else { return }
        cancelRecording()
    }
    
    @objc func sessionInterruptionEnded(_ notify: Notification) {}
}

// MARK: - Torch
extension MNMovieRecorder {
    var isTorching: Bool {
        guard let device = videoInput?.device, device.hasTorch else { return false }
        return device.torchMode == .on
    }
    
    func openTorch() {
        var isChangeFlash: Bool = false
        var isChangeTorch: Bool = false
        performDeviceChange { inputDevice in
            guard let device = inputDevice, device.hasTorch, device.torchMode != .on else { return }
            if device.hasFlash, device.flashMode == .on {
                // 关闭闪光灯
                isChangeFlash = true
                device.flashMode = .off
            }
            if device.isTorchModeSupported(.on) {
                isChangeTorch = true
                device.torchMode = .on
                //device.torchLevel = 0.5
            }
        }
        if isChangeTorch {
            delegate?.movieRecorder?(didChangeTorchScene: self)
        }
        if isChangeFlash {
            delegate?.movieRecorder?(didChangeFlashScene: self)
        }
    }
    
    func closeTorch() {
        var isChangeTorch: Bool = false
        performDeviceChange { inputDevice in
            guard let device = inputDevice, device.hasTorch, device.torchMode != .off else { return }
            if device.isTorchModeSupported(.off) {
                isChangeTorch = true
                device.torchMode = .off
            }
        }
        if isChangeTorch {
            delegate?.movieRecorder?(didChangeTorchScene: self)
        }
    }
}

// MARK: - Flash
extension MNMovieRecorder {
    var isFlashing: Bool {
        guard let device = videoInput?.device, device.hasFlash else { return false }
        return device.flashMode == .on
    }
    
    func openFlash() {
        var isChangeFlash: Bool = false
        var isChangeTorch: Bool = false
        performDeviceChange { inputDevice in
            guard let device = inputDevice, device.hasFlash, device.flashMode != .on else { return }
            if device.hasTorch, device.torchMode == .on {
                // 关闭手电筒
                isChangeTorch = true
                device.torchMode = .off
            }
            if device.isFlashModeSupported(.on) {
                isChangeFlash = true
                device.flashMode = .on
            }
        }
        if isChangeTorch {
            delegate?.movieRecorder?(didChangeTorchScene: self)
        }
        if isChangeFlash {
            delegate?.movieRecorder?(didChangeFlashScene: self)
        }
    }
    
    func closeFlash() {
        var isChangeFlash: Bool = false
        performDeviceChange { inputDevice in
            guard let device = inputDevice, device.hasFlash, device.flashMode != .off else { return }
            if device.isFlashModeSupported(.off) {
                isChangeFlash = true
                device.flashMode = .off
            }
        }
        if isChangeFlash {
            delegate?.movieRecorder?(didChangeFlashScene: self)
        }
    }
}

// MARK: - Focus
extension MNMovieRecorder {
    func update(focus point: CGPoint, completionHandler:((Bool)->Void)? = nil) {
        var result: Bool = false
        performDeviceChange { [weak self] inputDevice in
            guard let self = self, let device = inputDevice, device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) else { return }
            device.focusPointOfInterest = self.layer.captureDevicePointConverted(fromLayerPoint: point)
            device.focusMode = .autoFocus
            result = true
        }
        completionHandler?(result)
    }
}

// MARK: - Camera
extension MNMovieRecorder {
    
    func convertCamera(animation animationHandler:((CALayer, MovieDevicePosition)->Void)?, completion completionHandler:((Error?)->Void)? = nil) {
        convertCamera(position: self.devicePosition == .back ? .front : .back, animation: animationHandler, completion: completionHandler)
    }

    func convertCamera(position capturePosition: MovieDevicePosition, animation animationHandler:((CALayer, MovieDevicePosition)->Void)?, completion completionHandler:((Error?)->Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard capturePosition != self.devicePosition else {
                DispatchQueue.main.async {
                    completionHandler?(nil)
                }
                return
            }
            // 获取对应设备
            guard let device = self.device(position: capturePosition) else {
                DispatchQueue.main.async {
                    completionHandler?(AVError.recordError(.cannotConvertCamera))
                }
                return
            }
            // 建立新的输入对象
            var videoInput: AVCaptureDeviceInput!
            do {
                videoInput = try AVCaptureDeviceInput(device: device)
            } catch {
                DispatchQueue.main.async {
                    completionHandler?(AVError.recordError(.cannotConvertCamera))
                }
                return
            }
            // 手电筒/闪光灯设置
            let isTorching = self.isTorching
            if self.isFlashing { self.closeFlash() }
            if device.position == .front, isTorching { self.closeTorch() }
            // 添加input
            let isRunning = self.session.isRunning
            if isRunning { self.session.stopRunning() }
            self.session.beginConfiguration()
            if let oldInput = self.videoInput {
                self.session.removeInput(oldInput)
            }
            if self.session.canAddInput(videoInput) {
                // 添加新的设备输出
                self.session.addInput(videoInput)
                // 检查照片
                if #available(iOS 10.0, *), let photoOutput = self.photoOutput as? AVCapturePhotoOutput {
                    if photoOutput.isLivePhotoCaptureSupported {
                        photoOutput.isLivePhotoCaptureEnabled = true
                        photoOutput.isLivePhotoAutoTrimmingEnabled = true
                    }
                }
                if device.position == .front, let photoOutput = self.photoOutput, let photoConnection = photoOutput.connection(with: .video), photoConnection.isVideoMirroringSupported {
                    photoConnection.isVideoMirrored = true
                }
                self.session.commitConfiguration()
                // 检查配置
                do {
                    try device.lockForConfiguration()
                    if device.isSmoothAutoFocusSupported {
                        device.isSmoothAutoFocusEnabled = true
                    }
                    device.unlockForConfiguration()
                } catch {}
                // 替换
                self.videoInput = videoInput
                self.devicePosition = capturePosition
                if isRunning {
                    self.session.startRunning()
                }
                // 动画回调
                DispatchQueue.main.async {
                    animationHandler?(self.layer, capturePosition)
                }
                // 结束回调
                DispatchQueue.main.async {
                    completionHandler?(nil)
                }
            } else {
                if let oldInput = self.videoInput {
                    self.session.addInput(oldInput)
                }
                self.session.commitConfiguration()
                if isRunning { self.session.startRunning() }
                DispatchQueue.main.async {
                    completionHandler?(AVError.recordError(.cannotConvertCamera))
                }
            }
        }
    }
}

// MARK: - Recording
extension MNMovieRecorder {
    
    var videoTransform: CGAffineTransform {
        var angle: Double = .pi/2.0
        switch motior.orientation {
        case .portrait:
            if movieOrientation == .landscape {
                angle += .pi/2.0
            }
        case .landscapeLeft:
            if movieOrientation != .portrait {
                angle -= .pi/2.0
            }
        case .landscapeRight:
            if movieOrientation != .portrait {
                angle += .pi/2.0
            }
        case .portraitUpsideDown:
            if movieOrientation == .portrait {
                angle += .pi
            } else if movieOrientation == .landscape {
                angle -= .pi/2.0
            }
        default:
            break
        }
        return CGAffineTransform(rotationAngle: angle)
    }
    
    
    var isRecording: Bool { status == .recording }
    
    func startRecording() {
        // 检查是否在捕获
        guard isRunning else {
            update(status: .failed, error: .sessionError(.notRunning))
            return
        }
        guard sessionActive() else {
            update(status: .failed, error: .sessionError(.categoryNotActive(.record)))
            return
        }
        // 是否在录制
        if status == .recording { return }
        status = .recording
        // 开始写入数据
        movieWriter.url = url
        movieWriter.frameRate = frameRate
        movieWriter.transform = videoTransform
        movieWriter.startWriting()
    }
    
    func stopRecording() {
        guard status == .recording else { return }
        movieWriter.finishWriting()
    }
    
    func cancelRecording() {
        guard status == .recording else { return }
        movieWriter.cancelWriting()
    }
    
    func deleteRecording() {
        guard status != .recording, let _ = url else { return }
        try? FileManager.default.removeItem(at: url)
    }
    
    private func sessionActive() -> Bool {
        let category: AVAudioSession.Category = .playAndRecord
        if AVAudioSession.sharedInstance().category != category {
            do {
                try AVAudioSession.sharedInstance().setCategory(category)
            } catch {
                return false
            }
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            return false
        }
        return true
    }
}

// MARK: - MNMovieWriteDelegate
extension MNMovieRecorder: MNMovieWriteDelegate {
    
    func movieWriter(didStartWriting writer: MNMovieWriter) {
        update(status: .recording, error: nil)
    }
    
    func movieWriter(didFinishWriting writer: MNMovieWriter) {
        update(status: .finish, error: nil)
    }
    
    func movieWriter(didCancelWriting writer: MNMovieWriter) {
        update(status: .cancelled, error: nil)
    }
    
    func movieWriter(_ writer: MNMovieWriter, didFailWithError error: Error?) {
        update(status: .failed, error: error?.avError)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
extension MNMovieRecorder: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard status == .recording else { return }
        if let videoOutput = videoOutput, output == videoOutput {
            // 追加视频
            movieWriter.append(sampleBuffer: sampleBuffer, mediaType: .video)
        } else if let audioOutput = audioOutput, output == audioOutput {
            // 追加音频
            movieWriter.append(sampleBuffer: sampleBuffer, mediaType: .audio)
        }
    }
}

// MARK: - Photo
extension MNMovieRecorder {
    
    var photoOrientation: AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation = .portrait
        switch motior.orientation {
        case .portrait, .faceUp, .faceDown:
            orientation = movieOrientation.rawValue <= MovieOrientation.portrait.rawValue ? .portrait : .landscapeLeft
        case .landscapeLeft:
            orientation = movieOrientation == .portrait ? .portrait : .landscapeRight
        case .landscapeRight:
            orientation = movieOrientation == .portrait ? .portrait : .landscapeLeft
        case .portraitUpsideDown:
            if movieOrientation == .auto {
                orientation = .portrait
            } else if movieOrientation == .portrait {
                orientation = .portraitUpsideDown
            } else {
                orientation = .landscapeRight
            }
        default:
            orientation = .portrait
        }
        return orientation
    }
    
    
    func takePhoto() {
        
        guard isRunning else {
            delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.sessionError(.notRunning))
            return
        }
        
        guard isRecording == false else {
            delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.busying))
            return
        }
        
        if #available(iOS 10.0, *), let photoOutput = photoOutput as? AVCapturePhotoOutput {
            if #available(iOS 11.0, *) {
                guard photoOutput.availablePhotoCodecTypes.contains(.jpeg) else {
                    delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.unsupportedPhotoFormat))
                    return
                }
            }
            let settings = AVCapturePhotoSettings()
            settings.isHighResolutionPhotoEnabled = true
            let isOn: Bool = delegate?.movieRecorder?(shouldUsingFlash: self) ?? false
            settings.flashMode = isOn ? .on : .off
            if #available(iOS 13.0, *) {
                settings.photoQualityPrioritization = .balanced
            } else {
                settings.isAutoStillImageStabilizationEnabled = true
            }
            if let photoConnection = photoOutput.connection(with: .video), photoConnection.isVideoOrientationSupported {
                photoConnection.videoOrientation = photoOrientation
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        } else if let photoOutput = photoOutput as? AVCaptureStillImageOutput {
            guard let photoConnection = photoOutput.connection(with: .video) else {
                delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.cannotCapturePhoto))
                return
            }
            if photoConnection.isVideoOrientationSupported {
                photoConnection.videoOrientation = photoOrientation
            }
            photoOutput.captureStillImageAsynchronously(from: photoConnection) { [weak self] imageDataSampleBuffer, error in
                guard let self = self else { return }
                guard let sampleBuffer = imageDataSampleBuffer, error == nil, let photo = MNCapturePhoto(imageData: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)) else {
                    DispatchQueue.main.async {
                        self.delegate?.movieRecorder?(self, didTakingPhoto: nil, error: error == nil ? AVError.captureError(.cannotCapturePhoto) : AVError.captureError(.underlyingError(error!)))
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.delegate?.movieRecorder?(self, didTakingPhoto: photo, error: nil)
                }
            }
        } else {
            delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.photoOutputNotFound))
        }
    }
    
    func takeLivePhoto() {
        
        guard isRunning else {
            delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.sessionError(.notRunning))
            return
        }
        guard isRecording == false else {
            delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.busying))
            return
        }
        if #available(iOS 10.0, *) {
            
            guard let photoOutput = photoOutput as? AVCapturePhotoOutput else {
                delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.cannotCaptureLivePhoto))
                return
            }
            guard photoOutput.isLivePhotoCaptureSupported, photoOutput.isLivePhotoCaptureEnabled else {
                delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.cannotCaptureLivePhoto))
                return
            }
            let movUrl = URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!)/photo/live.mov")
            try? FileManager.default.removeItem(at: movUrl)
            do {
                try FileManager.default.createDirectory(at: movUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            } catch {
                delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.urlError(.cannotCreateDirectory(movUrl.deletingLastPathComponent().path)))
                return
            }
            let settings = AVCapturePhotoSettings()
            settings.livePhotoMovieFileURL = movUrl
            photoOutput.isLivePhotoCaptureSuspended = false
            if #available(iOS 11.0, *), photoOutput.availableLivePhotoVideoCodecTypes.count > 0 {
                settings.livePhotoVideoCodecType = photoOutput.availableLivePhotoVideoCodecTypes.first!
            }
            if let photoConnection = photoOutput.connection(with: .video), photoConnection.isVideoOrientationSupported {
                photoConnection.videoOrientation = photoOrientation
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        } else {
            delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.cannotCaptureLivePhoto))
        }
    }
    
    func startTakingLivePhoto() {
        guard isRecording == false else {
            delegate?.movieRecorder?(didChangeSessionPreset: self, error: AVError.captureError(.busying))
            return
        }
        guard #available(iOS 10.0, *), let photoOutput = self.photoOutput as? AVCapturePhotoOutput else {
            delegate?.movieRecorder?(didChangeSessionPreset: self, error: AVError.captureError(.cannotCaptureLivePhoto))
            return
        }
        guard session.canSetSessionPreset(.photo) else {
            delegate?.movieRecorder?(didChangeSessionPreset: self, error: AVError.captureError(.cannotCaptureLivePhoto))
            return
        }
        guard session.sessionPreset != .photo else {
            delegate?.movieRecorder?(didChangeSessionPreset: self, error: nil)
            return
        }
        // 判断录音权限
        MNAuthorization.requestMicrophone(using: sessionQueue) { [weak self] result in
            guard result else {
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.delegate?.movieRecorder?(didChangeSessionPreset: self, error: AVError.notPermission(.microphoneDenied))
                }
                return
            }
            guard let self = self else { return }
            self.session.sessionPreset = .photo
            self.sessionPreset = .photo
            if photoOutput.isLivePhotoCaptureSupported, photoOutput.isLivePhotoCaptureEnabled == false {
                let isRunning = self.session.isRunning
                if isRunning { self.session.stopRunning() }
                photoOutput.isLivePhotoCaptureEnabled = true
                photoOutput.isLivePhotoAutoTrimmingEnabled = true
                if isRunning { self.session.startRunning() }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.movieRecorder?(didChangeSessionPreset: self, error: nil)
            }
        }
    }
    
    func stopTakingLivePhoto() {
        guard isRecording == false else {
            delegate?.movieRecorder?(didChangeSessionPreset: self, error: AVError.captureError(.busying))
            return
        }
        guard session.sessionPreset == .photo else {
            delegate?.movieRecorder?(didChangeSessionPreset: self, error: nil)
            return
        }
        guard session.canSetSessionPreset(lastSessionPreset) else {
            delegate?.movieRecorder?(didChangeSessionPreset: self, error: AVError.sessionError(.unsupportedPreset(lastSessionPreset)))
            return
        }
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.sessionPreset = self.lastSessionPreset
            self.sessionPreset = self.lastSessionPreset
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.movieRecorder?(didChangeSessionPreset: self, error: nil)
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension MNMovieRecorder: AVCapturePhotoCaptureDelegate {
    @available(iOS 10.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if isMuteTaking {
            AudioServicesDisposeSystemSoundID(1110-2)
        }
        let isLivePhoto = (resolvedSettings.livePhotoMovieDimensions.width + resolvedSettings.livePhotoMovieDimensions.height) > 0
        DispatchQueue.main.async {
            self.delegate?.movieRecorder?(beginTakingPhoto: self, isLivePhoto: isLivePhoto)
        }
    }
//    @available(iOS 10.0, *)
//    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
//
//    }
    @available(iOS 10.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        photoQueue.async { [weak self] in
            
            guard let self = self else { return }
            
            let isLivePhoto = (resolvedSettings.livePhotoMovieDimensions.width + resolvedSettings.livePhotoMovieDimensions.height) > 0
            
            if let sampleBuffer = photoSampleBuffer, let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer), let photo = MNCapturePhoto(imageData: imageData) {
                if isLivePhoto {
                    // 保存图片
                    self.livePhoto = photo
                    DispatchQueue.main.async {
                        self.delegate?.movieRecorder?(self, didTakingLiveStillImage: photo)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.delegate?.movieRecorder?(self, didTakingPhoto: photo, error: nil)
                    }
                }
            } else if isLivePhoto == false {
                DispatchQueue.main.async {
                    self.delegate?.movieRecorder?(self, didTakingPhoto: nil, error: error == nil ? AVError.captureError(.cannotCapturePhoto) : AVError.captureError(.underlyingError(error!)))
                }
            }
        }
    }
    @available(iOS 10.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        photoQueue.async { [weak self] in
            
            guard let self = self else { return }
            
            if let _ = error {
                DispatchQueue.main.async {
                    self.delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.underlyingError(error!)))
                }
                return
            }
            
            guard let livePhoto = self.livePhoto, FileManager.default.fileExists(atPath: outputFileURL.path)  else {
                self.livePhoto = nil
                DispatchQueue.main.async {
                    self.delegate?.movieRecorder?(self, didTakingPhoto: nil, error: AVError.captureError(.cannotCaptureLivePhoto))
                }
                return
            }
            
            self.livePhoto = nil
            livePhoto.isLivePhoto = true
            livePhoto.duration = duration
            livePhoto.videoURL = outputFileURL
            livePhoto.photoDisplayTime = photoDisplayTime
        
            DispatchQueue.main.async {
                self.delegate?.movieRecorder?(self, didTakingPhoto: livePhoto, error: nil)
            }
        }
    }
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        photoQueue.async { [weak self] in
            guard let self = self else { return }
            let resolvedSettings = photo.resolvedSettings
            let isLivePhoto = (resolvedSettings.livePhotoMovieDimensions.width + resolvedSettings.livePhotoMovieDimensions.height) > 0
            if let result = MNCapturePhoto(imageData: photo.fileDataRepresentation()) {
                if isLivePhoto {
                    // 保存图片
                    result.isLivePhoto = true
                    self.livePhoto = result
                    DispatchQueue.main.async {
                        self.delegate?.movieRecorder?(self, didTakingLiveStillImage: result)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.delegate?.movieRecorder?(self, didTakingPhoto: result, error: nil)
                    }
                }
            } else if isLivePhoto == false {
                DispatchQueue.main.async {
                    self.delegate?.movieRecorder?(self, didTakingPhoto: nil, error: error == nil ? AVError.captureError(.cannotCapturePhoto) : AVError.captureError(.underlyingError(error!)))
                }
            }
        }
    }
}

// MARK: -
extension MNMovieRecorder {
    /// 请求权限
    /// - Parameter completionHandler: 回调结果
    func requestAuthorization(completion completionHandler: (Bool)->Void) {
        
    }
}
