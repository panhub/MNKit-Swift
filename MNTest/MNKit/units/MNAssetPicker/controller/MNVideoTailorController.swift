//
//  MNVideoTailorController.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/23.
//  视频裁剪

import UIKit
import AVFoundation

class MNVideoTailorController: UIViewController {
    
    private var videoPath: String = ""
    
    private var isFailed: Bool = false
    
    private var thumbnail: UIImage!
    
    private var duration: TimeInterval = 0.0
    
    private var naturalSize: CGSize = CGSize(width: 1920.0, height: 1080.0)
    
    var minTailorDuration: TimeInterval = 0.0
    
    var maxTailorDuration: TimeInterval = 0.0
    
    private let closeButton = UIButton(type: .custom)
    
    private let doneButton = UIButton(type: .custom)
    
    private let timeLabel: UILabel = UILabel()
    
    private let badgeView: UIImageView = UIImageView(image: MNAssetPicker.image(named: "player_play"))
    
    private let playView: MNPlayView = MNPlayView()
    
    private let playControl: UIControl = UIControl(frame: CGRect(x: 0.0, y: 0.0, width: 48.0, height: 48.0))
    
    private let BlackColor: UIColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    
    private let WhiteColor: UIColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
    
    override var prefersStatusBarHidden: Bool { false }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }
    
    private lazy var tailorView: MNVideoTailorView = {
        let tailorView: MNVideoTailorView = MNVideoTailorView(frame: CGRect(x: playControl.frame.maxX + 1.5, y: playControl.frame.minY, width: doneButton.frame.maxX - playControl.frame.maxX - 1.5, height: playControl.frame.height))
        tailorView.delegate = self
        tailorView.videoPath = videoPath
        tailorView.minTailorDuration = minTailorDuration
        tailorView.maxTailorDuration = maxTailorDuration
        tailorView.layer.mask(radius: 5.0, corners: [.topRight, .bottomRight])
        return tailorView
    }()
    
    private let indicatorView: UIActivityIndicatorView = {
        var style: UIActivityIndicatorView.Style
        if #available(iOS 13.0, *) {
            style = .large
        } else {
            style = .whiteLarge
        }
        let indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: style)
        indicatorView.hidesWhenStopped = true
        indicatorView.isUserInteractionEnabled = false
        return indicatorView
    }()
    
    private lazy var player: MNPlayer = {
        let player = MNPlayer(urls: [URL(fileURLWithPath: videoPath)])
        player.delegate = self
        player.layer = playView.layer
        //player.observeTime = CMTime(value: 1, timescale: 60)
        return player
    }()
    
    convenience init(url: URL) {
        self.init(videoPath: url.path)
    }
    
    convenience init(videoPath: String) {
        self.init(nibName: nil, bundle: nil)
        self.videoPath = videoPath
        self.duration = MNAssetExporter.duration(mediaAtPath: videoPath)
        self.thumbnail = MNAssetExporter.thumbnail(videoAtPath: videoPath)
        let naturalSize = MNAssetExporter.naturalSize(videoAtPath: videoPath)
        if naturalSize != .zero {
            self.naturalSize = naturalSize
        }
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
        
        closeButton.size = CGSize(width: 30.0, height: 30.0)
        closeButton.minX = 15.0
        closeButton.maxY = view.frame.height - max(15.0, MN_TAB_SAFE_HEIGHT)
        closeButton.setBackgroundImage(MNAssetPicker.image(named: "player_close"), for: .normal)
        closeButton.setBackgroundImage(closeButton.currentBackgroundImage, for: .highlighted)
        closeButton.addTarget(self, action: #selector(closeButtonTouchUpInside(_:)), for: .touchUpInside)
        view.addSubview(closeButton)
        
        doneButton.size = CGSize(width: 28.0, height: 28.0)
        doneButton.midY = closeButton.frame.midY
        doneButton.maxX = view.frame.width - closeButton.frame.minX
        doneButton.setBackgroundImage(MNAssetPicker.image(named: "player_done"), for: .normal)
        doneButton.setBackgroundImage(closeButton.currentBackgroundImage, for: .highlighted)
        doneButton.setBackgroundImage(closeButton.currentBackgroundImage, for: .disabled)
        doneButton.isEnabled = false
        doneButton.addTarget(self, action: #selector(doneButtonTouchUpInside(_:)), for: .touchUpInside)
        view.addSubview(doneButton)
        
        timeLabel.frame = CGRect(x: closeButton.frame.maxX, y: closeButton.frame.minY, width: doneButton.frame.minX - closeButton.frame.maxX, height: closeButton.frame.height)
        timeLabel.numberOfLines = 1
        timeLabel.font = .systemFont(ofSize: 12.0, weight: .medium)
        timeLabel.textAlignment = .center
        timeLabel.text = "00:00/00:00"
        timeLabel.textColor = WhiteColor
        view.addSubview(timeLabel)
        
        playControl.minX = closeButton.frame.minX
        playControl.maxY = closeButton.frame.minY - 20.0
        playControl.isUserInteractionEnabled = false
        playControl.backgroundColor = BlackColor
        playControl.layer.mask(radius: 5.0, corners: [.topLeft, .bottomLeft])
        playControl.addTarget(self, action: #selector(playControlTouchUpInside(_:)), for: .touchUpInside)
        view.addSubview(playControl)
        
        badgeView.width = 25.0
        badgeView.sizeFitToWidth()
        badgeView.isUserInteractionEnabled = false
        badgeView.highlightedImage = MNAssetPicker.image(named: "player_pause")
        badgeView.center = CGPoint(x: playControl.bounds.midX, y: playControl.bounds.midY)
        playControl.addSubview(badgeView)
        
        tailorView.isUserInteractionEnabled = false
        tailorView.backgroundColor = BlackColor
        view.addSubview(tailorView)
        
        // 播放尺寸
        let top: CGFloat = MN_STATUS_BAR_HEIGHT + MN_NAV_BAR_HEIGHT/2.0
        let width: CGFloat = view.frame.width
        let height: CGFloat = playControl.frame.minY - 20.0 - top
        var naturalSize: CGSize = naturalSize
        if naturalSize.width >= naturalSize.height {
            // 横向视频
            naturalSize = naturalSize.multiplyTo(width: width)
            if floor(naturalSize.height) > height {
                naturalSize = self.naturalSize.multiplyTo(height: height)
            }
        } else {
            // 纵向视频
            naturalSize = naturalSize.multiplyTo(height: height)
            if floor(naturalSize.width) > width {
                naturalSize = self.naturalSize.multiplyTo(width: width)
            }
        }
        naturalSize.width = ceil(naturalSize.width)
        naturalSize.height = ceil(naturalSize.height)
        playView.frame = CGRect(x: (view.frame.width - naturalSize.width)/2.0, y: (height - naturalSize.height)/2.0 + top, width: naturalSize.width, height: naturalSize.height)
        playView.minX = (view.frame.width - naturalSize.width)/2.0
        playView.isTouchEnabled = false
        playView.backgroundColor = BlackColor
        view.addSubview(playView)
        
        indicatorView.center = playView.center
        indicatorView.color = WhiteColor
        view.addSubview(indicatorView)
        
        if duration > 0.0, let _ = thumbnail {
            indicatorView.startAnimating()
            playView.coverView.image = thumbnail
            timeLabel.text = "00:00/\(Date(timeIntervalSince1970: ceil(duration)).timeValue)"
            tailorView.reloadData()
        } else {
            isFailed = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isFailed else { return }
        isFailed = false
        failure("初始化视频失败")
    }
    
    private func failure(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.pop()
        }))
    }
}

// MARK: - Event
extension MNVideoTailorController {
    
    @objc func closeButtonTouchUpInside(_ sender: UIButton) {
        pop()
    }
    
    @objc func doneButtonTouchUpInside(_ sender: UIButton) {
        
    }
    
    //
    @objc func playControlTouchUpInside(_ sender: UIButton) {
        
    }
}

// MARK: - MNVideoTailorViewDelegate
extension MNVideoTailorController: MNVideoTailorViewDelegate {
    
    func tailorViewBeginLoadThumbnail(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewLoadThumbnailNotSatisfy(_ tailorView: MNVideoTailorView) {
        indicatorView.stopAnimating()
        failure("视频不满足裁剪条件")
    }
    
    func tailorViewDidEndLoadThumbnail(_ tailorView: MNVideoTailorView) {
        tailorView.isUserInteractionEnabled = true
        indicatorView.startAnimating()
        player.play()
    }
    
    func tailorViewLoadThumbnailsFailed(_ tailorView: MNVideoTailorView) {
        indicatorView.stopAnimating()
        failure("无法加载视频截图")
    }
    
    func tailorViewLeftHandlerBeginDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewLeftHandlerDidDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewLeftHandlerEndDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewRightHandlerBeginDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewRightHandlerDidDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewRightHandlerEndDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewPointerBeginDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewPointerDidDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewPointerDidEndDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewBeginDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewDidDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewDidEndDragging(_ tailorView: MNVideoTailorView) {
        
    }
    
    func tailorViewDidEndPlaying(_ tailorView: MNVideoTailorView) {
        
    }
}

// MARK: - MNPlayerDelegate
extension MNVideoTailorController: MNPlayerDelegate {
    
    func player(_ player: MNPlayer, didPlayFailure error: Error) {
        indicatorView.stopAnimating()
        failure("视频播放失败")
    }
    
    func player(didChangeState player: MNPlayer) {
        if player.isPlaying {
            badgeView.isHighlighted = true
            if playView.coverView.alpha == 1.0 {
                indicatorView.stopAnimating()
                UIView.animate(withDuration: 0.18, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
                    guard let self = self else { return }
                    self.playView.coverView.alpha = 0.0
                }, completion: nil)
            }
        } else {
            badgeView.isHighlighted = false
        }
    }
}
