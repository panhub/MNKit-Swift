//
//  MNCameraPreview.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/12/20.
//  拍摄预览

import UIKit
import PhotosUI

class MNCameraPreview: UIView {
    
    private lazy var scrollView: MNAssetScrollView = {
        let scrollView = MNAssetScrollView(frame: bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return scrollView
    }()
    
    private lazy var playView: MNPlayView = {
        let playView = MNPlayView(frame: scrollView.contentView.bounds)
        playView.isHidden = true
        playView.coverView.isHidden = true
        playView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return playView
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.isHidden = true
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }()
    
    lazy var badgeView: UIImageView = {
        let badgeView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 43.0, height: 43.0))
        badgeView.center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
        badgeView.alpha = 0.0
        badgeView.clipsToBounds = true
        badgeView.contentMode = .scaleAspectFill
        badgeView.isUserInteractionEnabled = false
        badgeView.image = MNAssetPicker.image(named: "record_preview_play")
        badgeView.highlightedImage = MNAssetPicker.image(named: "record_preview_pause")
        badgeView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        return badgeView
    }()
    
    @available(iOS 9.1, *)
    private lazy var livePhotoView: PHLivePhotoView = {
        let livePhotoView = PHLivePhotoView(frame: scrollView.contentView.bounds)
        livePhotoView.isHidden = true
        livePhotoView.clipsToBounds = true
        livePhotoView.contentMode = .scaleAspectFit
        livePhotoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return livePhotoView
    }()
    
    private lazy var player: MNPlayer = {
        let player = MNPlayer()
        player.delegate = self
        player.layer = playView.layer
        return player
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        addSubview(scrollView)
        scrollView.contentView.addSubview(playView)
        if #available(iOS 9.1, *) {
            scrollView.contentView.addSubview(livePhotoView)
        }
        scrollView.contentView.addSubview(imageView)
        addSubview(badgeView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MNCameraPreview {
    
    func play() {
        guard playView.isHidden == false, player.state != .failed else { return }
        player.play()
    }
    
    func pause() {
        if playView.isHidden == false, player.state != .failed {
            player.pause()
        } else if #available(iOS 9.1, *), livePhotoView.isHidden == false {
            livePhotoView.stopPlayback()
        }
    }
    
    func stop() {
        badgeView.alpha = 0.0
        imageView.image = nil
        imageView.isHidden = true
        if playView.isHidden == false {
            player.removeAll()
            playView.isHidden = true
        }
        if #available(iOS 9.1, *), livePhotoView.isHidden == false {
            livePhotoView.stopPlayback()
            livePhotoView.livePhoto = nil
            livePhotoView.isHidden = true
        }
    }
}

extension MNCameraPreview {
    
    func preview(image: UIImage) {
        badgeView.alpha = 0.0
        playView.isHidden = true
        if #available(iOS 9.1, *) {
            livePhotoView.isHidden = true
        }
        imageView.isHidden = false
        aspectScrollView(usingImage: image)
        imageView.image = image
    }
    
    func previewVideo(url: URL) {
        guard let image = MNAssetExporter.thumbnail(videoAtPath: url.path) else { return }
        preview(image: image)
        player.removeAll()
        player.add([url])
        player.play()
    }
    
    func previewLivePhoto(using imageData: Data, videoURL: URL) {
        guard #available(iOS 9.1, *), let image = UIImage(data: imageData) else { return }
        preview(image: image)
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let imageURL = URL(fileURLWithPath: "\(path)/livepreview/image.jpeg")
        let videoURL = URL(fileURLWithPath: "\(path)/livepreview/image.mov")
        MNAssetHelper.requestLivePhoto(resourceFileURLs: [imageURL, videoURL]) { [weak self] livePhoto, _ in
            guard let self = self, self.alpha == 1.0 else { return }
            guard let photo = livePhoto else {
                self.superview?.showErrorToast("export live faild")
                return
            }
            self.imageView.isHidden = true
            self.livePhotoView.isHidden = false
            self.livePhotoView.livePhoto = photo
            self.livePhotoView.startPlayback(with: .full)
        }
    }
    
    private func aspectScrollView(usingImage image: UIImage) {
        scrollView.zoomScale = 1.0
        scrollView.contentOffset = .zero
        scrollView.size = image.size.scaleAspectFit(toSize: scrollView.frame.size)
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: max(scrollView.frame.height, scrollView.contentView.frame.height))
        scrollView.contentView.center = CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY)
        if scrollView.contentView.frame.height > scrollView.frame.height {
            scrollView.contentView.minY = 0.0
            scrollView.contentOffset = CGPoint(x: 0.0, y: (scrollView.contentView.frame.height - scrollView.frame.height)/2.0)
        }
    }
}

extension MNCameraPreview: MNPlayerDelegate {
    func player(didEndDecode player: MNPlayer) {
        badgeView.alpha = 0.0
        playView.isHidden = false
        badgeView.isHidden = false
        badgeView.transform = .identity
    }
    
    func player(didChangeState player: MNPlayer) {
        if player.state == .playing {
            if badgeView.alpha == 1.0 {
                badgeView.isHighlighted = true
                badgeView.transform = .identity
                UIView.animate(withDuration: MNAssetCaptureBar.AnimationDuration) { [weak self] in
                    self?.badgeView.alpha = 0.0
                    self?.badgeView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                }
            }
        } else if player.state == .pause {
            badgeView.alpha = 1.0
            badgeView.isHighlighted = false
            badgeView.transform = .identity
        }
    }
    
    func player(shouldPlayNextItem player: MNPlayer) -> Bool {
        true
    }
    
    func player(_ player: MNPlayer, didPlayFailure error: Error) {
        superview?.showErrorToast(error.localizedDescription)
    }
}
