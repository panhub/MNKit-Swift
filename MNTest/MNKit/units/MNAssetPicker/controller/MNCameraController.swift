//
//  MNCameraController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/27.
//  拍照控制器

import UIKit

class MNCameraController: UIViewController {
    
    /**配置信息**/
    lazy var options: MNAssetPickerOptions = {
        return MNAssetPickerOptions()
    }()
    
    /**视频路径**/
    var outputURL: URL?
    
    /**最大拍摄时长**/
    var maxCaptureDuration: TimeInterval = 60.0
    
    private lazy var movieView: UIView = {
        let movieView = UIView(frame: view.bounds)
        movieView.backgroundColor = .black
        movieView.clipsToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(recognizer:)))
        tap.numberOfTapsRequired = 1
        movieView.addGestureRecognizer(tap)
        return movieView
    }()
    
    private lazy var preview: MNCameraPreview = {
        let preview = MNCameraPreview(frame: view.bounds)
        preview.alpha = 0.0
        return preview
    }()
    
    private lazy var toolBar: MNAssetCaptureBar = {
        var functions: MNAssetCaptureBar.Function = []
        if options.isAllowsPickingVideo {
            functions = functions.union(.video)
        }
        if options.isAllowsPickingPhoto {
            functions = functions.union(.photo)
        }
        let toolBar = MNAssetCaptureBar(frame: CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: 0.0))
        toolBar.maxY = view.bounds.height - MN_TAB_SAFE_HEIGHT - 60.0
        toolBar.delegate = self
        toolBar.options = functions
        toolBar.timeoutInterval = max(maxCaptureDuration, options.maxExportDuration)
        return toolBar
    }()
    
    private lazy var cameraButton: UIButton = {
        let cameraButton = UIButton(type: .custom)
        cameraButton.frame = CGRect(x: view.bounds.width - 60.0, y: (MN_NAV_BAR_HEIGHT - 40.0)/2.0 + MN_STATUS_BAR_HEIGHT, width: 40.0, height: 40.0)
        cameraButton.setBackgroundImage(MNAssetPicker.image(named: "record_camera"), for: .normal)
        cameraButton.setBackgroundImage(MNAssetPicker.image(named: "record_camera"), for: .highlighted)
        cameraButton.addTarget(self, action: #selector(convert(sender:)), for: .touchUpInside)
        return cameraButton
    }()
    
    private lazy var liveButton: UIButton = {
        let liveButton = UIButton(type: .custom)
        liveButton.frame = CGRect(x: view.bounds.width - cameraButton.frame.maxX, y: (MN_NAV_BAR_HEIGHT - 32.0)/2.0 + MN_STATUS_BAR_HEIGHT, width: 32.0, height: 32.0)
        liveButton.setBackgroundImage(MNAssetPicker.image(named: "live_photo_off"), for: .normal)
        liveButton.setBackgroundImage(MNAssetPicker.image(named: "live_photo"), for: .selected)
        if #available(iOS 10.0, *) {
            liveButton.isHidden = (options.isAllowsPickingPhoto && options.isAllowsPickingLivePhoto && options.isUsingPhotoPolicyPickingLivePhoto == false) == false
        } else {
            liveButton.isHidden = false
        }
        return liveButton
    }()
    
    private lazy var liveLabel: UILabel = {
        let liveLabel = UILabel(frame: .zero)
        liveLabel.alpha = 0.0
        liveLabel.font = UIFont.systemFont(ofSize: 13.0)
        liveLabel.text = "实况"
        liveLabel.textColor = .white
        liveLabel.textAlignment = .center
        liveLabel.numberOfLines = 1
        liveLabel.sizeToFit()
        liveLabel.width = ceil(liveLabel.width + 10.0)
        liveLabel.height = ceil(liveLabel.height + 6.0)
        liveLabel.center = CGPoint(x: view.bounds.width/2.0, y: cameraButton.frame.midY)
        liveLabel.layer.cornerRadius = 3.0
        liveLabel.clipsToBounds = true
        liveLabel.backgroundColor = UIColor(red: 249.0/255.0, green: 213.0/255.0, blue: 74.0/255.0, alpha: 1.0)
        return liveLabel
    }()
    
    private lazy var focusView: UIImageView = {
        let focusView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 55.0, height: 55.0))
        focusView.isHidden = true
        focusView.image = MNAssetPicker.image(named: "record_focus")?.renderBy(color: .white)
        return focusView
    }()
    
    private lazy var recorder: MNMovieRecorder = {
        let recorder = MNMovieRecorder()
        recorder.delegate = self
        recorder.movieOrientation = .auto
        recorder.resizeMode = .resizeAspectFill
        recorder.outputView = movieView
        recorder.url = outputURL ?? URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)/record/\(Int(NSDate().timeIntervalSince1970*1000)).mp4")
        return recorder
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .black
        
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        if #available(iOS 11.0, *) {
            additionalSafeAreaInsets = .zero
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        view.addSubview(movieView)
        view.addSubview(preview)
        view.addSubview(cameraButton)
        view.addSubview(liveButton)
        view.addSubview(liveLabel)
        view.addSubview(toolBar)
        view.addSubview(focusView)
        
        var presetSize = (recorder.presetSizeRatio == .ratio9x16 ? CGSize(width: 9.0, height: 16.0) : CGSize(width: 3.0, height: 4.0)).multiplyTo(width: movieView.bounds.width)
        presetSize.height = ceil(presetSize.height)
        if abs(presetSize.height - movieView.bounds.height) <= 2.0 { presetSize.height = movieView.bounds.height }
        if movieView.bounds.height == presetSize.height {
            cameraButton.minY = MN_STATUS_BAR_HEIGHT
            liveLabel.midY = cameraButton.midY
            liveButton.midY = cameraButton.midY
            let h: CGFloat = ceil(CGSize(width: 3.0, height: 4.0).multiplyTo(width: movieView.bounds.width).height)
            let m: CGFloat = floor((view.bounds.height - h - cameraButton.frame.maxY - toolBar.frame.height)/3.0)
            toolBar.maxY = view.bounds.height - m
        } else {
            preview.size = presetSize
            movieView.size = presetSize
            var m: CGFloat = floor((view.bounds.height - cameraButton.frame.maxY - MN_TAB_SAFE_HEIGHT - presetSize.height - toolBar.frame.height)/3.0)
            if m > (MNAssetCaptureBar.MaxHeight - MNAssetCaptureBar.MinHeight) {
                preview.minY = cameraButton.frame.maxY + m
                movieView.minY = cameraButton.frame.maxY + m
                toolBar.minY = cameraButton.frame.maxY + presetSize.height + m*2.0
            } else {
                m = floor((view.bounds.height - cameraButton.frame.maxY - MN_TAB_SAFE_HEIGHT - presetSize.height)/2.0)
                preview.minY = cameraButton.frame.maxY + m
                movieView.minY = cameraButton.frame.maxY + m
                toolBar.maxY = cameraButton.frame.maxY + m + presetSize.height - (MNAssetCaptureBar.MaxHeight - MNAssetCaptureBar.MinHeight)
            }
        }
        
        if toolBar.options.contains(.video), toolBar.options.contains(.photo) {
            recorder.prepareCapturing()
        } else if toolBar.options.contains(.photo) {
            //recorder.prepareTaking()
        } else if toolBar.options.contains(.video) {
            //recorder.prepareRecording()
        }
    }
}

// MARK: - Event
private extension MNCameraController {
    @objc func tap(recognizer: UITapGestureRecognizer) {
        guard focusView.isHidden, recorder.isRunning else { return }
        let location = recognizer.location(in: movieView)
        focusView.center = location
        focusView.isHidden = false
        focusView.transform = .identity
        UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
            self?.focusView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) { [weak self] in
            self?.recorder.update(focus: location, completionHandler: { _ in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                    self?.focusView.isHidden = true
                    self?.focusView.transform = .identity
                }
            })
        }
    }
    
    @objc func convert(sender: UIButton) {
        sender.isUserInteractionEnabled = false
        recorder.convertCamera { layer, position in
            let animation = CATransition()
            animation.duration = 0.38
            animation.type = CATransitionType(rawValue: "oglFlip")
            animation.subtype = position == .back ? .fromRight : .fromLeft
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(animation, forKey: "convert")
        } completion: { [weak self] error in
            sender.isUserInteractionEnabled = true
            if let _ = error {
                self?.view.showErrorToast(error!.avError!.errMsg)
                return
            }
        }
    }
}

extension MNCameraController: MNAssetCaptureBarDelegate {
    func captureBar(closeButtonTouchUpInside toolBar: MNAssetCaptureBar) {
        if options.isAllowsAutoDismiss {
            
        } else {
            //config.delegate?.assetPicker?(didCancel: <#T##MNAssetPicker#>)
        }
    }
    
    func captureBar(backButtonTouchUpInside toolBar: MNAssetCaptureBar) {
        toolBar.resetCapturing()
        recorder.startRunning()
        UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
            self?.preview.alpha = 0.0
            self?.liveButton.alpha = 1.0
            self?.movieView.alpha = 1.0
            self?.cameraButton.alpha = 1.0
        } completion: { [weak self] _ in
            self?.preview.stop()
            self?.recorder.deleteRecording()
        }
    }
    
    func captureBar(doneButtonTouchUpInside toolBar: MNAssetCaptureBar) {
        
    }
    
    func captureBar(shouldCapturingVideo toolBar: MNAssetCaptureBar) -> Bool {
        liveButton.isSelected == false
    }
    
    func captureBar(shouldTakingPhoto toolBar: MNAssetCaptureBar) -> Bool {
        liveLabel.alpha == 0.0
    }
    
    func captureBar(beginCapturingVideo toolBar: MNAssetCaptureBar) {
        recorder.startRecording()
    }
    
    func captureBar(endCapturingVideo toolBar: MNAssetCaptureBar) {
        recorder.stopRecording()
    }
    
    func captureBar(beginTakingPhoto toolBar: MNAssetCaptureBar) {
        view.isUserInteractionEnabled = false
        if liveButton.isSelected {
            recorder.takeLivePhoto()
        } else {
            recorder.takePhoto()
        }
    }
}

extension MNCameraController: MNMovieRecordDelegate {
    func movieRecorder(didStartRecording recorder: MNMovieRecorder) {
        toolBar.startCapturing()
        UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
            self?.liveButton.alpha = 0.0
        }
    }
    
    func movieRecorder(didFinishRecording recorder: MNMovieRecorder) {
        toolBar.stopCapturing()
        recorder.stopRunning()
        preview.previewVideo(url: recorder.url!)
        UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
            self?.preview.alpha = 1.0
            self?.liveButton.alpha = 0.0
            self?.movieView.alpha = 0.0
            self?.cameraButton.alpha = 0.0
        }
    }
    
    func movieRecorder(didCancelRecording recorder: MNMovieRecorder) {
        toolBar.resetCapturing()
    }
    
    func movieRecorder(beginTakingPhoto recorder: MNMovieRecorder, isLivePhoto: Bool) {
        view.isUserInteractionEnabled = false
        if isLivePhoto {
            UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
                self?.liveLabel.alpha = 1.0
            }
        }
    }
    
    func movieRecorder(_ recorder: MNMovieRecorder, didTakingPhoto photo: MNCapturePhoto?, error: Error?) {
        if liveLabel.alpha == 1.0 {
            liveLabel.layer.removeAllAnimations()
            UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
                self?.liveLabel.alpha = 0.0
            }
        }
        guard let _ = photo else {
            view.isUserInteractionEnabled = true
            view.showErrorToast(error?.avError?.errMsg ?? "发生未知错误")
            return
        }
        toolBar.stopCapturing()
        if photo!.isLivePhoto {
            preview.previewLivePhoto(using: photo!.imageData!, videoURL: photo!.videoURL!)
        } else {
            preview.preview(image: photo!.image!)
        }
        UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
            self?.preview.alpha = 1.0
            self?.liveButton.alpha = 0.0
            self?.movieView.alpha = 0.0
            self?.cameraButton.alpha = 0.0
        } completion: { [weak self] _ in
            self?.recorder.stopRunning()
            self?.view.isUserInteractionEnabled = true
        }
    }
    
    func movieRecorder(_ recorder: MNMovieRecorder, didFailWithError error: Error?) {
        //let avError = error!.avError!
        view.showErrorToast(error!.avError!.errMsg)
    }
}
