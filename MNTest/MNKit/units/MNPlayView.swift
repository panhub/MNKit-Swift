//
//  MNPlayView.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/8.
//  播放器画布

import UIKit
import AVFoundation

@objc protocol MNPlayViewDelegate: NSObjectProtocol {
    @objc optional func playViewShouldReceiveTouch(_ playView: MNPlayView) -> Bool
    @objc optional func playViewTouchUpInside(_ playView: MNPlayView) -> Void
}

extension AVLayerVideoGravity {
    /// AVLayerVideoGravity => UIView.ContentMode
    var mode: UIView.ContentMode {
        switch self {
        case .resize: return .scaleToFill
        case .resizeAspect: return .scaleAspectFit
        case .resizeAspectFill: return .scaleAspectFill
        default: return .scaleToFill
        }
    }
}

class MNPlayView: UIView {
    
    @objc weak var delegate: MNPlayViewDelegate?
    
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    
    @objc var gravity: AVLayerVideoGravity {
        get { (layer as? AVPlayerLayer)?.videoGravity ?? .resize }
        set {
            coverView.contentMode = newValue.mode
            (layer as? AVPlayerLayer)?.videoGravity = newValue
        }
    }
    
    private lazy var tap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(clicked(_:)))
        tap.isEnabled = false
        tap.numberOfTapsRequired = 1
        return tap
    }()
    
    /**是否响应点击事件**/
    @objc var isTouchEnabled: Bool {
        get { tap.isEnabled }
        set { tap.isEnabled = newValue }
    }
    
    private(set) lazy var coverView: UIImageView = {
        let coverView = UIImageView(frame: bounds)
        coverView.clipsToBounds = true
        coverView.backgroundColor = .clear
        coverView.contentMode = .scaleAspectFit
        coverView.isUserInteractionEnabled = false
        coverView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return coverView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        gravity = .resizeAspect
        addSubview(coverView)
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Event
extension MNPlayView {
    @objc func clicked(_ recognizer: UITapGestureRecognizer) {
        delegate?.playViewTouchUpInside?(self)
    }
}

// MARK: - Event
extension MNPlayView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return delegate?.playViewShouldReceiveTouch?(self) ?? true
    }
}
