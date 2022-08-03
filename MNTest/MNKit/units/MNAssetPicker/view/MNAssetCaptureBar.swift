//
//  MNAssetCaptureBar.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/17.
//  拍摄控制栏

import UIKit

@objc protocol MNAssetCaptureBarDelegate: NSObjectProtocol {
    @objc optional func captureBar(shouldTakingPhoto toolBar: MNAssetCaptureBar) -> Bool
    @objc optional func captureBar(shouldCapturingVideo toolBar: MNAssetCaptureBar) -> Bool
    @objc optional func captureBar(closeButtonTouchUpInside toolBar: MNAssetCaptureBar) -> Void
    @objc optional func captureBar(backButtonTouchUpInside toolBar: MNAssetCaptureBar) -> Void
    @objc optional func captureBar(doneButtonTouchUpInside toolBar: MNAssetCaptureBar) -> Void
    @objc optional func captureBar(beginCapturingVideo toolBar: MNAssetCaptureBar) -> Void
    @objc optional func captureBar(endCapturingVideo toolBar: MNAssetCaptureBar) -> Void
    @objc optional func captureBar(beginTakingPhoto toolBar: MNAssetCaptureBar) -> Void
}

class MNAssetCaptureBar: UIView {
    
    private enum State: Int {
        case idle
        case locked
        case capturing
        case finish
    }
    
    struct Function: OptionSet {
        // 图片
        static let photo = Function(rawValue: 1 << 1)
        // 视频
        static let video = Function(rawValue: 1 << 2)
        // 全部
        static let all: Function = [.video, .photo]
        
        let rawValue: UInt
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
    
    static let MinHeight: CGFloat = 75.0
    static let TransformScale: CGFloat = 1.35
    static let MaxHeight: CGFloat = MinHeight*TransformScale
    static let AnimationDuration: TimeInterval = 0.3
    
    /**功能**/
    var options: Function = .all
    /**当前状态**/
    private var state: State = .idle
    /**拍摄时长**/
    var timeoutInterval: TimeInterval = 0.0
    /**事件代理**/
    weak var delegate: MNAssetCaptureBarDelegate?
    
    private lazy var trackView: UIView = {
        let trackView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: MNAssetCaptureBar.MinHeight, height: MNAssetCaptureBar.MinHeight))
        trackView.clipsToBounds = true
        trackView.layer.cornerRadius = trackView.bounds.height/2.0
        trackView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        trackView.backgroundColor = UIColor(red: 225.0/255.0, green: 225.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        return trackView
    }()
    
    private lazy var touchView: UIView = {
        let touchView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 55.0, height: 55.0))
        touchView.center = trackView.center
        touchView.clipsToBounds = true
        touchView.layer.cornerRadius = touchView.bounds.height/2.0
        touchView.backgroundColor = .white
        touchView.isUserInteractionEnabled = false
        return touchView
    }()
    
    private lazy var progressLayer: CAShapeLayer = {
        let path: UIBezierPath = UIBezierPath(roundedRect: trackView.bounds.inset(by: UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)), cornerRadius: trackView.layer.cornerRadius)
        let progressLayer = CAShapeLayer()
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.blue.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 4.0
        progressLayer.strokeEnd = 0.0
        return progressLayer
    }()
    
    private lazy var backButton: UIButton = {
        let backButton = UIButton(type: .custom)
        backButton.frame = CGRect(x: 0.0, y: 0.0, width: 70.0, height: 70.0)
        backButton.center = trackView.center
        backButton.setBackgroundImage(MNAssetPicker.image(named: "record_return"), for: .normal)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        return backButton
    }()
    
    private lazy var doneButton: UIButton = {
        let doneButton = UIButton(type: .custom)
        doneButton.frame = CGRect(x: 0.0, y: 0.0, width: 70.0, height: 70.0)
        doneButton.center = trackView.center
        doneButton.setBackgroundImage(MNAssetPicker.image(named: "record_done"), for: .normal)
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        return doneButton
    }()
    
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton(type: .custom)
        closeButton.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        closeButton.center = CGPoint(x: trackView.frame.minX/2.0, y: trackView.frame.midY)
        closeButton.setBackgroundImage(MNAssetPicker.image(named: "record_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        return closeButton
    }()
    
    private lazy var animation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.delegate = self
        animation.duration = timeoutInterval
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.autoreverses = false
        animation.beginTime = CACurrentMediaTime()
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: max(frame.width, MNAssetCaptureBar.MinHeight), height: max(frame.height, MNAssetCaptureBar.MinHeight)))
        
        addSubview(trackView)
        addSubview(touchView)
        trackView.layer.addSublayer(progressLayer)
        insertSubview(backButton, belowSubview: trackView)
        insertSubview(doneButton, belowSubview: trackView)
        addSubview(closeButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        if let _ = superview {
            if let gestureRecognizers = gestureRecognizers {
                for gestureRecognizer in gestureRecognizers {
                    removeGestureRecognizer(gestureRecognizer)
                }
            }
            if options.contains(.photo) {
                let tap = UITapGestureRecognizer()
                tap.delegate = self
                tap.numberOfTapsRequired = 1
                tap.addTarget(self, action: #selector(tap(recognizer:)))
                addGestureRecognizer(tap)
            }
            if options.contains(.video) {
                let press = UILongPressGestureRecognizer()
                press.delegate = self
                press.numberOfTapsRequired = 1
                press.minimumPressDuration = 0.3
                press.addTarget(self, action: #selector(press(recognizer:)))
                addGestureRecognizer(press)
            }
        }
        super.didMoveToSuperview()
    }
}

// MARK: - Event
private extension MNAssetCaptureBar {
    @objc func back() {
        delegate?.captureBar?(backButtonTouchUpInside: self)
    }
    
    @objc func close() {
        delegate?.captureBar?(closeButtonTouchUpInside: self)
    }
    
    @objc func done() {
        delegate?.captureBar?(doneButtonTouchUpInside: self)
    }
    
    @objc func tap(recognizer: UITapGestureRecognizer) {
        guard state == .idle else { return }
        delegate?.captureBar?(beginTakingPhoto: self)
    }
    
    @objc func press(recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            if state == .idle {
                beginCapturing()
            }
        case .ended:
            if state == .capturing {
                endCapturing()
            }
        case .possible, .changed:
            break
        default:
            UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
                guard let self = self else { return }
                self.closeButton.alpha = 1.0
                self.trackView.transform = .identity
                self.touchView.transform = .identity
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.progressLayer.isHidden = true
                self.progressLayer.removeAllAnimations()
                self.progressLayer.strokeEnd = 0.0
                self.state = .idle
            }
        }
    }
}

private extension MNAssetCaptureBar {
    func beginCapturing() {
        state = .locked
        progressLayer.speed = 1.0
        progressLayer.timeOffset = 0.0
        progressLayer.beginTime = 0.0
        delegate?.captureBar?(beginCapturingVideo: self)
    }
    
    func endCapturing() {
        state = .locked
        let timeOffset = progressLayer.convertTime(CACurrentMediaTime(), from: nil)
        progressLayer.speed = 0.0
        progressLayer.timeOffset = timeOffset
        delegate?.captureBar?(endCapturingVideo: self)
    }
}

extension MNAssetCaptureBar {
    
    func startCapturing() {
        clipsToBounds = false
        state = .locked
        UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
            guard let self = self else { return }
            self.closeButton.alpha = 0.0
            self.touchView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            self.trackView.transform = CGAffineTransform(scaleX: MNAssetCaptureBar.TransformScale, y: MNAssetCaptureBar.TransformScale)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.state = .capturing
            self.progressLayer.isHidden = false
            if self.timeoutInterval > 0.0 {
                self.progressLayer.add(self.animation, forKey: "strokeEnd")
            }
        }
    }
    
    func stopCapturing() {
        state = .locked
        UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
            guard let self = self else { return }
            self.trackView.transform = .identity
            self.touchView.transform = .identity
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.progressLayer.isHidden = true
            self.progressLayer.speed = 1.0
            self.progressLayer.timeOffset = 0.0
            self.progressLayer.beginTime = 0.0
            self.progressLayer.removeAllAnimations()
            self.progressLayer.strokeEnd = 0.0
            self.touchView.alpha = 0.0
            self.trackView.alpha = 0.0
            self.doneButton.alpha = 1.0
            self.backButton.alpha = 1.0
            self.doneButton.center = CGPoint(x: self.trackView.frame.midX, y: self.trackView.frame.midY)
            UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
                guard let self = self else { return }
                self.closeButton.alpha = 0.0
                self.backButton.minX = self.closeButton.minX
                self.doneButton.maxX = self.width - self.closeButton.minX
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.state = .finish
            }
        }
    }
    
    func resetCapturing() {
        guard state.rawValue > State.locked.rawValue else { return }
        let old = state
        state = .locked
        if old == .capturing {
            UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
                guard let self = self else { return }
                self.touchView.transform = .identity
                self.trackView.transform = .identity
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.progressLayer.isHidden = true
                self.progressLayer.speed = 1.0
                self.progressLayer.timeOffset = 0.0
                self.progressLayer.beginTime = 0.0
                self.progressLayer.removeAllAnimations()
                self.progressLayer.strokeEnd = 0.0
                self.state = .idle
            }
        } else {
            UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
                guard let self = self else { return }
                self.closeButton.alpha = 1.0
                self.doneButton.alpha = 0.0
                self.trackView.alpha = 1.0
                self.touchView.alpha = 1.0
                self.backButton.midX = self.bounds.width/2.0
                self.doneButton.midX = self.bounds.width/2.0
                self.trackView.midX = self.bounds.width/2.0
                self.touchView.midX = self.bounds.width/2.0
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.backButton.alpha = 0.0
                self.state = .idle
            }
        }
    }
}

// MARK: - CAAnimationDelegate
extension MNAssetCaptureBar: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        endCapturing()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MNAssetCaptureBar: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            return delegate?.captureBar?(shouldTakingPhoto: self) ?? true
        } else if gestureRecognizer is UILongPressGestureRecognizer {
            return delegate?.captureBar?(shouldCapturingVideo: self) ?? true
        }
        return false
    }
}
