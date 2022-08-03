//
//  MNAssetBrowserCell.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/8.
//  资源浏览器Cell

import UIKit
import Photos
import PhotosUI

class MNAssetBrowserCell: UICollectionViewCell {
    /**定义状态*/
    private enum State {
        case normal, loading, downloading, previewing
    }
    /**资源模型*/
    private(set) var asset: MNAsset!
    /**当前状态*/
    private var state: State = .normal
    /**是否允许自动播放*/
    var isAllowsAutoPlaying: Bool = false
    /**视频控制栏高度*/
    static let ToolBarHeight: CGFloat = MN_TAB_SAFE_HEIGHT + 60.0
    /**Live标记**/
    private var liveBadgeView: UIImageView!
    
    lazy var scrollView: MNAssetScrollView = {
        let scrollView = MNAssetScrollView(frame: bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return scrollView
    }()
    
    private lazy var playView: MNPlayView = {
        let playView = MNPlayView(frame: scrollView.contentView.bounds)
        playView.backgroundColor = .clear
        playView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return playView
    }()
    
    @available(iOS 9.1, *)
    private lazy var livePhotoView: PHLivePhotoView = {
        let livePhotoView = PHLivePhotoView(frame: scrollView.contentView.bounds)
        livePhotoView.clipsToBounds = true
        livePhotoView.contentMode = .scaleAspectFit
        livePhotoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        livePhotoView.delegate = self
        liveBadgeView = UIImageView(frame: CGRect(x: 11.0, y: 11.0, width: 27.0, height: 27.0))
        liveBadgeView.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        liveBadgeView.contentMode = .scaleToFill
        //liveBadgeView.image = PHLivePhotoView.livePhotoBadgeImage(options: [.liveOff])
        liveBadgeView.image = PHLivePhotoView.livePhotoBadgeImage()
        livePhotoView.addSubview(liveBadgeView)
        
        return livePhotoView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: scrollView.contentView.bounds)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }()
    
    private lazy var progressView: MNAssetProgressView = {
        let progressView = MNAssetProgressView(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0))
        progressView.center = CGPoint(x: contentView.bounds.width/2.0, y: contentView.bounds.height/2.0)
        progressView.isHidden = true
        progressView.layer.cornerRadius = progressView.bounds.width/2.0
        progressView.clipsToBounds = true
        return progressView
    }()
    
    private lazy var toolBar: UIImageView = {
        let toolBar = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: contentView.bounds.width, height: MNAssetBrowserCell.ToolBarHeight))
        toolBar.maxY = contentView.bounds.height
        toolBar.image = MNAssetPicker.image(named: "bottom")
        toolBar.isUserInteractionEnabled = true
        toolBar.contentMode = .scaleToFill
        return toolBar
    }()
    
    private lazy var playButton: UIButton = {
        let playButton = UIButton(type: .custom)
        playButton.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        playButton.minX = 7.0
        playButton.midY = (toolBar.bounds.height - MN_TAB_SAFE_HEIGHT)/2.0
        playButton.adjustsImageWhenHighlighted = false
        playButton.setBackgroundImage(MNAssetPicker.image(named: "browser_play"), for: .normal)
        playButton.setBackgroundImage(MNAssetPicker.image(named: "browser_pause"), for: .selected)
        playButton.addTarget(self, action: #selector(playButtonTouchUpInside), for: .touchUpInside)
        return playButton
    }()
    
    private lazy var timeLabel: UILabel = {
        let timeLabel = UILabel(frame: .zero)
        timeLabel.text = "00:00"
        timeLabel.textColor = .white
        timeLabel.font = UIFont.systemFont(ofSize: 12.0)
        timeLabel.sizeToFit()
        timeLabel.width += 8.0
        timeLabel.midY = playButton.midY
        timeLabel.minX = playButton.maxX + 5.0
        return timeLabel
    }()
    
    private lazy var durationLabel: UILabel = {
        let durationLabel = UILabel(frame: .zero)
        durationLabel.textColor = timeLabel.textColor
        durationLabel.font = timeLabel.font
        durationLabel.text = "00:00"
        durationLabel.sizeToFit()
        durationLabel.width += 8.0
        durationLabel.textAlignment = .right
        durationLabel.maxX = toolBar.width - 15.0
        durationLabel.midY = playButton.midY
        return durationLabel
    }()
    
    private lazy var slider: MNSlider = {
        let slider = MNSlider(frame: CGRect(x: timeLabel.maxX, y: 0.0, width: durationLabel.minX - timeLabel.maxX, height: 16.0))
        slider.midY = playButton.midY
        slider.trackHeight = 3.0
        slider.borderWidth = 0.0
        slider.progressColor = .white
        slider.trackColor = .white.withAlphaComponent(0.2)
        slider.bufferColor = .white.withAlphaComponent(0.2)
        slider.delegate = self
        return slider
    }()
    
    private lazy var player: MNPlayer = {
        let player = MNPlayer()
        player.delegate = self
        player.layer = playView.layer
        player.observeTime = CMTime(value: 1, timescale: 40)
        return player
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        contentView.frame = bounds
        contentView.clipsToBounds = true
        contentView.backgroundColor = .clear
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentView.addSubview(scrollView)
        scrollView.contentView.addSubview(playView)
        if #available(iOS 9.1, *) {
            scrollView.contentView.addSubview(livePhotoView)
        }
        scrollView.contentView.addSubview(imageView)
        contentView.addSubview(progressView)
        
        contentView.addSubview(toolBar)
        toolBar.addSubview(playButton)
        toolBar.addSubview(timeLabel)
        toolBar.addSubview(durationLabel)
        toolBar.addSubview(slider)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 更新
extension MNAssetBrowserCell {
    
    func update(asset: MNAsset) {
        self.asset = asset
        state = .loading
        imageView.image = nil
        imageView.isHidden = asset.type == .video
        playView.isHidden = asset.type != .video
        progressView.isHidden = true
        playButton.isSelected = false
        toolBar.isHidden = playView.isHidden
        if #available(iOS 9.1, *) {
            livePhotoView.isHidden = true
        }
        if toolBar.isHidden == false {
            slider.set(progress: 0.0)
            timeLabel.text = "00:00"
            durationLabel.text = "00:00"
            toolBar.maxY = toolBar.superview!.bounds.height
        }
        
        // 获取缩略图
        MNAssetHelper.thumbnail(asset: asset) { [weak self] asset, thumbnail in
            
            guard let self = self, self.state == .loading, let _ = self.asset, asset == self.asset! else { return }
            
            var image: UIImage = thumbnail
            if let content = asset.content, let img = content as? UIImage { image = img }
            if let images = image.images, images.count > 1 { image = images.first! }
            
            self.update(image: image)
            
            if asset.type == .video {
                self.playView.coverView.image = image
                self.playView.coverView.isHidden = false
            } else {
                self.imageView.image = image
            }
            
            if asset.progress > 0.0 {
                self.progressView.isHidden = false
                self.progressView.set(progress: asset.progress)
            }
            
            // 获取内容
            self.state = .downloading
            MNAssetHelper.content(asset: asset) { [weak self] progress, error, m in
                
                guard let self = self, let _ = self.asset, m == self.asset! else { return }
                
                if error != nil || progress <= 0.0 {
                    self.progressView.isHidden = true
                    self.progressView.set(progress: 0.0)
                } else {
                    self.progressView.isHidden = false
                    self.progressView.set(progress: progress)
                }
            } completion: { [weak self] m in
                
                guard let self = self, let _ = self.asset, m == self.asset! else { return }
                
                self.progressView.isHidden = true
                self.update()
            }
        }
    }
    
    func beginDisplaying() {
        state = .previewing
        update()
    }
    
    func endDisplaying() {
        state = .normal
        if asset.type == .video {
            player.removeAll()
            playView.coverView.image = nil
        } else if asset.type == .livePhoto {
            if #available(iOS 9.1, *) {
                guard let _ = livePhotoView.livePhoto else { return }
                livePhotoView.stopPlayback()
                livePhotoView.livePhoto = nil
            }
        }
        asset?.cancelRequest()
        asset?.cancelDownload()
    }
    
    func pauseDisplaying() {
        guard let _ = asset else { return }
        if asset.type == .video {
            player.pause()
        } else if asset.type == .livePhoto {
            if #available(iOS 9.1, *) {
                guard let _ = livePhotoView.livePhoto else { return }
                livePhotoView.stopPlayback()
                // 解决滑动过程中播放的问题
                livePhotoView.playbackGestureRecognizer.isEnabled = false
                livePhotoView.playbackGestureRecognizer.isEnabled = true
            }
        }
    }
    
    private func update() {
        guard state == .previewing, let content = asset?.content else { return }
        if asset.type == .video {
            player.add([URL(fileURLWithPath: content as! String)])
            if isAllowsAutoPlaying {
                player.play()
            }
        } else if asset.type == .livePhoto {
            if #available(iOS 9.1, *) {
                livePhotoView.livePhoto = content as? PHLivePhoto
                if let _ = livePhotoView.livePhoto {
                    imageView.isHidden = true
                    livePhotoView.isHidden = false
                    if isAllowsAutoPlaying {
                        livePhotoView.startPlayback(with: .full)
                    }
                }
            }
        } else {
            guard let image = content as? UIImage else { return }
            update(image: image)
            imageView.image = image
        }
    }
    
    private func update(image: UIImage) {
        scrollView.zoomScale = 1.0
        scrollView.contentOffset = .zero
        scrollView.contentView.size = image.size.scaleAspectFit(toSize: scrollView.bounds.size)
        scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: max(scrollView.contentView.bounds.height, scrollView.bounds.height))
        scrollView.contentView.center = CGPoint(x: scrollView.bounds.maxX/2.0, y: scrollView.bounds.maxY/2.0)
        if (scrollView.contentView.bounds.height > scrollView.bounds.height) {
            scrollView.contentView.minY = 0.0
            scrollView.contentOffset = CGPoint(x: 0.0, y: (scrollView.contentView.bounds.height - scrollView.bounds.height)/2.0)
        }
    }
    
    func updateToolBar(visible isVisible: Bool, animated isAnimated: Bool) {
        guard toolBar.isHidden == false else { return }
        UIView.animate(withDuration: isAnimated ? 0.3 : 0.0, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.toolBar.minY = self.contentView.bounds.height - (isVisible ? self.toolBar.bounds.height : 0.0)
        }, completion: nil)
    }
}

// MARK: - 播放控制
extension MNAssetBrowserCell {
    func makePlayToolBarVisible(_ isVisible: Bool, animated: Bool) {
        UIView.animate(withDuration: (animated ? UIApplication.shared.statusBarOrientationAnimationDuration : Double.leastNormalMagnitude), delay: 0.0, options: [.curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.toolBar.minY = self.contentView.height - (isVisible ? self.toolBar.height : 0.0)
        }, completion: nil)
    }
    
    @objc func playButtonTouchUpInside(_ sender: UIButton) {
        guard player.state != .failed else { return }
        if player.state == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
}

// MARK: - 当前视图
extension MNAssetBrowserCell {
    var currentImage: UIImage? {
        guard let asset = asset else { return nil }
        if asset.type == .video || asset.type == .livePhoto { return asset.thumbnail }
        guard let image = asset.content as? UIImage else { return asset.thumbnail }
        guard let images = image.images, images.count > 1 else { return image }
        return images.first
    }
}

// MARK: - MNPlayerDelegate
extension MNAssetBrowserCell: MNPlayerDelegate {
    
    func player(didEndDecode player: MNPlayer) {
        durationLabel.text = Date(timeIntervalSince1970: TimeInterval(player.duration)).timeValue
    }
    
    func player(didChangeState player: MNPlayer) {
        playButton.isSelected = player.state == .playing
        if player.state.rawValue > MNPlayer.PlayState.failed.rawValue {
            if playView.coverView.isHidden == false {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
                    self?.playView.coverView.isHidden = true
                }
            }
        } else {
            playView.coverView.isHidden = false
        }
    }
    
    func player(didPlayTimeInterval player: MNPlayer) {
        slider.set(progress: player.progress)
        timeLabel.text = Date(timeIntervalSince1970: player.current).timeValue
    }
    
    func player(_ player: MNPlayer, didPlayFailure error: Error) {
        let msg = error.avError?.errMsg ?? "播放失败"
        contentView.showInfoToast(msg)
    }
}

// MARK: - MNSliderDelegate
extension MNAssetBrowserCell: MNSliderDelegate {
    
    func slider(shouldBeginDragging: MNSlider) -> Bool {
        return player.state.rawValue > MNPlayer.PlayState.failed.rawValue
    }
    
    func slider(shouldBeginTouching: MNSlider) -> Bool {
        return player.state.rawValue > MNPlayer.PlayState.failed.rawValue
    }
    
    func slider(willBeginDragging: MNSlider) {
        player.pause()
    }
    
    func slider(didDragging slider: MNSlider) {
        player.seek(toProgress: slider.progress, completion: nil)
    }
    
    func slider(didEndDragging slider: MNSlider) {
        player.play()
    }
    
    func slider(willBeginTouching: MNSlider) {
        player.pause()
    }
    
    func slider(didEndTouching slider: MNSlider) {
        player.seek(toProgress: slider.progress) { [weak self] finish in
            guard finish, let self = self else { return }
            self.player.play()
        }
    }
}

@available(iOS 9.1, *)
extension MNAssetBrowserCell: PHLivePhotoViewDelegate {
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, canBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) -> Bool {
        liveBadgeView.alpha == 1.0
    }
    
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.liveBadgeView.alpha = 0.0
        }
    }
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.liveBadgeView.alpha = 1.0
        }
    }
}
