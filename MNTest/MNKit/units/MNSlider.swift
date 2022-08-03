//
//  MNSlider.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/9.
//  进度滑块

import UIKit

// MARK: - 事件代理
@objc protocol MNSliderDelegate: NSObjectProtocol {
    @objc optional func slider(shouldBeginDragging slider: MNSlider) -> Bool
    @objc optional func slider(willBeginDragging slider: MNSlider) -> Void
    @objc optional func slider(didDragging slider: MNSlider) -> Void
    @objc optional func slider(didEndDragging slider: MNSlider) -> Void
    @objc optional func slider(shouldBeginTouching slider: MNSlider) -> Bool
    @objc optional func slider(willBeginTouching slider: MNSlider) -> Void
    @objc optional func slider(didEndTouching slider: MNSlider) -> Void
}

class MNSlider: UIView {
    /**事件代理*/
    weak var delegate: MNSliderDelegate?
    /**缓冲*/
    private(set) var buffer: Float = 0.0
    /**进度*/
    private(set) var progress: Float = 0.0
    /**是否在拖拽*/
    private(set) var isDragging: Bool = false
    /**内容视图*/
    private lazy var contentView: UIView = {
        let contentView = UIView(frame: bounds)
        contentView.backgroundColor = .clear
        contentView.isUserInteractionEnabled = true
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return contentView
    }()
    /**轨迹*/
    private lazy var trackView: UIView = {
        let trackView = UIView(frame: CGRect(x: contentView.bounds.height/2.0, y: (contentView.bounds.height - 4.0)/2.0, width: contentView.bounds.width - contentView.bounds.height, height: 4.0))
        trackView.clipsToBounds = true
        trackView.isUserInteractionEnabled = false
        trackView.layer.cornerRadius = trackView.bounds.height/2.0
        trackView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin]
        trackView.backgroundColor = .clear
        trackView.layer.borderWidth = 0.8
        trackView.layer.borderColor = UIColor.black.withAlphaComponent(0.8).cgColor
        return trackView
    }()
    /**缓冲*/
    private lazy var bufferView: UIView = {
        let bufferView = UIView(frame: trackView.bounds.inset(by: UIEdgeInsets(top: trackView.layer.borderWidth, left: trackView.layer.borderWidth, bottom: trackView.layer.borderWidth, right: trackView.layer.borderWidth)))
        bufferView.clipsToBounds = true
        bufferView.isUserInteractionEnabled = false
        bufferView.layer.cornerRadius = bufferView.bounds.height/2.0
        bufferView.autoresizingMask = [.flexibleHeight]
        bufferView.backgroundColor = UIColor(cgColor: trackView.layer.borderColor!)
        return bufferView
    }()
    /**进度*/
    private lazy var progressView: UIView = {
        let progressView = UIView(frame: trackView.frame)
        progressView.clipsToBounds = true
        progressView.isUserInteractionEnabled = false
        progressView.layer.cornerRadius = progressView.bounds.height/2.0
        progressView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        progressView.backgroundColor = .white
        return progressView
    }()
    /**滑块*/
    private lazy var thumbView: UIImageView = {
        let thumbView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: contentView.bounds.height, height: contentView.bounds.height))
        thumbView.isUserInteractionEnabled = true
        thumbView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        thumbView.backgroundColor = .white.withAlphaComponent(0.5)
        thumbView.layer.cornerRadius = thumbView.bounds.height/2.0
        thumbView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        thumbView.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        thumbView.layer.shadowOpacity = 0.3
        thumbView.layer.shadowRadius = 1.0
        thumbView.contentMode = .scaleAspectFill
        return thumbView
    }()
    /**滑块上圆点*/
    private lazy var touchView: UIView = {
        let inset: CGFloat = floor((thumbView.bounds.height - max(trackView.bounds.height, thumbView.bounds.height/3.0))/2.0)
        let touchView = UIView(frame: thumbView.bounds.inset(by: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)))
        touchView.clipsToBounds = true
        touchView.isUserInteractionEnabled = false
        touchView.backgroundColor = .white
        touchView.layer.cornerRadius = touchView.bounds.height/2.0
        return touchView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: max(frame.width, 10.0), height: max(frame.height, 4.0)))
        
        isUserInteractionEnabled = true
        
        addSubview(contentView)
        contentView.addSubview(trackView)
        trackView.addSubview(bufferView)
        contentView.addSubview(progressView)
        contentView.addSubview(thumbView)
        thumbView.addSubview(touchView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(recognizer:)))
        pan.delegate = self
        thumbView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(recognizer:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
        
        tap.require(toFail: pan)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        set(buffer: buffer)
        set(progress: progress)
    }
}

extension MNSlider: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            if let allow = delegate?.slider?(shouldBeginTouching: self), allow == false { return false}
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if let allow = delegate?.slider?(shouldBeginDragging: self), allow == false { return false}
        }
        return true
    }
}

// MARK: - 交互处理
extension MNSlider {
    
    @objc func pan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            delegate?.slider?(willBeginDragging: self)
            isDragging = true
        case .changed:
            let translation = recognizer.translation(in: recognizer.view)
            recognizer.setTranslation(.zero, in: recognizer.view)
            var tframe = thumbView.frame
            tframe.origin.x += translation.x
            tframe.origin.x = min(max(0.0, tframe.origin.x), contentView.bounds.width - tframe.width)
            thumbView.frame = tframe
            updateProgress()
            delegate?.slider?(didDragging: self)
        case .ended:
            isDragging = false
            delegate?.slider?(didEndDragging: self)
        default:
            isDragging = false
        }
    }
    
    @objc func tap(recognizer: UITapGestureRecognizer) {
        delegate?.slider?(willBeginTouching: self)
        let location = recognizer.location(in: recognizer.view)
        var tframe = thumbView.frame
        tframe.origin.x = location.x - tframe.width/2.0
        tframe.origin.x = min(max(0.0, tframe.origin.x), contentView.bounds.width - tframe.width)
        thumbView.frame = tframe
        updateProgress()
        delegate?.slider?(didEndTouching: self)
    }
    
    func updateProgress() {
        var pframe = progressView.frame
        pframe.size.width = thumbView.frame.minX
        progressView.frame = pframe
        progress = Float(progressView.frame.width/trackView.frame.width)
    }
}

// MARK: - 修改进度/缓冲
extension MNSlider {
    func set(progress: Float, animated: Bool = false) {
        guard isDragging == false else { return }
        self.progress = min(max(0.0, progress), 1.0)
        var pframe = progressView.frame
        pframe.size.width = trackView.frame.width*CGFloat(self.progress)
        var tframe = thumbView.frame
        tframe.origin.x = pframe.width
        if animated {
            thumbView.layer.removeAllAnimations()
            progressView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut) { [weak self] in
                self?.thumbView.frame = tframe
                self?.progressView.frame = pframe
            } completion: { _ in }
        } else {
            thumbView.frame = tframe
            progressView.frame = pframe
        }
    }
    
    func set(buffer: Float, animated: Bool = false) {
        self.buffer = min(max(0.0, buffer), 1.0)
        var bframe = thumbView.frame
        bframe.size.width = trackView.bounds.inset(by: UIEdgeInsets(top: trackView.layer.borderWidth, left: trackView.layer.borderWidth, bottom: trackView.layer.borderWidth, right: trackView.layer.borderWidth)).width*CGFloat(self.buffer)
        if animated {
            thumbView.layer.removeAllAnimations()
            progressView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut) { [weak self] in
                self?.bufferView.frame = bframe
            } completion: { _ in }
        } else {
            bufferView.frame = bframe
        }
    }
}

// MARK: - Buid UI
extension MNSlider {
    // 修改轨迹
    var trackHeight: CGFloat {
        get { trackView.frame.height }
        set {
            guard trackView.frame.height != newValue else { return }
            let tresizing = trackView.autoresizingMask
            trackView.autoresizingMask = []
            var tframe = trackView.frame
            tframe.size.height = newValue
            tframe.origin.y = (contentView.frame.height - newValue)/2.0
            trackView.frame = tframe
            trackView.autoresizingMask = tresizing
            let presizing = progressView.autoresizingMask
            progressView.autoresizingMask = []
            var pframe = progressView.frame
            pframe.size.height = tframe.height
            pframe.origin.y = tframe.minY
            progressView.frame = pframe
            progressView.autoresizingMask = presizing
        }
    }
    
    var trackColor: UIColor? {
        get { trackView.backgroundColor }
        set { trackView.backgroundColor = newValue }
    }
    
    var borderColor: UIColor? {
        get {
            guard let color = trackView.layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set { trackView.layer.borderColor = newValue?.cgColor }
    }
    
    var borderWidth: CGFloat {
        get { trackView.layer.borderWidth }
        set { trackView.layer.borderWidth = newValue }
    }
    
    var thumbColor: UIColor? {
        get { thumbView.backgroundColor }
        set { thumbView.backgroundColor = newValue }
    }
    
    var touchColor: UIColor? {
        get { touchView.backgroundColor }
        set { touchView.backgroundColor = newValue }
    }
    
    var thumbImage: UIImage? {
        get { thumbView.image }
        set { thumbView.image = newValue }
    }
    
    var bufferColor: UIColor? {
        get { bufferView.backgroundColor }
        set { bufferView.backgroundColor = newValue }
    }
    
    var progressColor: UIColor? {
        get { progressView.backgroundColor }
        set { progressView.backgroundColor = newValue }
    }
    
    var isShowShadow: Bool {
        get { thumbView.clipsToBounds == false }
        set { thumbView.clipsToBounds = !newValue }
    }
    
    var shadowColor: UIColor? {
        get {
            guard let color = thumbView.layer.shadowColor else { return nil }
            return UIColor(cgColor: color)
        }
        set { thumbView.layer.shadowColor = newValue?.cgColor }
    }
}
