//
//  MNVideoTailorView.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/23.
//  视频裁剪控制

import UIKit
import AVFoundation

protocol MNVideoTailorViewDelegate: NSObjectProtocol {
    
    func tailorViewBeginLoadThumbnail(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewLoadThumbnailNotSatisfy(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewDidEndLoadThumbnail(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewLoadThumbnailsFailed(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewLeftHandlerBeginDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewLeftHandlerDidDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewLeftHandlerEndDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewRightHandlerBeginDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewRightHandlerDidDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewRightHandlerEndDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewPointerBeginDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewPointerDidDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewPointerDidEndDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewBeginDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewDidDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewDidEndDragging(_ tailorView: MNVideoTailorView) -> Void
    
    func tailorViewDidEndPlaying(_ tailorView: MNVideoTailorView) -> Void
}

class MNVideoTailorView: UIView {
    
    enum SeekStatus {
        case none, dragging, touching
    }
    
    var status: SeekStatus = .none
    
    var videoPath: String = ""
    
    let pointer: UIView = UIView()
    
    let scrollView: UIScrollView = UIScrollView()
    
    let leftMaskView: MNVideoKeyfram = MNVideoKeyfram()
    
    let rightMaskView: MNVideoKeyfram = MNVideoKeyfram()
    
    let thumbnailView: MNVideoKeyfram = MNVideoKeyfram()
    
    let tailorHandler: MNTailorHandler = MNTailorHandler()
    
    var minTailorDuration: TimeInterval = 0.0
    
    var maxTailorDuration: TimeInterval = 0.0
    
    var isDragging: Bool = false
    
    var isEnding: Bool = false
    
    weak var delegate: MNVideoTailorViewDelegate?
    
    let AnimationDuration: TimeInterval = 0.2
    
    private let BlackColor: UIColor = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    
    private let WhiteColor: UIColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
    
    private let indicatorView: UIActivityIndicatorView = {
        var style: UIActivityIndicatorView.Style
        if #available(iOS 13.0, *) {
            style = .medium
        } else {
            style = .white
        }
        let indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: style)
        indicatorView.hidesWhenStopped = true
        indicatorView.isUserInteractionEnabled = false
        return indicatorView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let contentInset = UIEdgeInsets(top: 3.5, left: 23.0, bottom: 3.5, right: 23.0)
        
        scrollView.frame = bounds.inset(by: contentInset)
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .black
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(scrollView)
        
        thumbnailView.frame = scrollView.bounds
        thumbnailView.clipsToBounds = true
        thumbnailView.backgroundColor = .clear
        thumbnailView.isUserInteractionEnabled = false
        scrollView.addSubview(thumbnailView)
        
        leftMaskView.frame = scrollView.bounds
        leftMaskView.isUserInteractionEnabled = false
        scrollView.addSubview(leftMaskView)
        
        rightMaskView.frame = scrollView.bounds
        rightMaskView.isUserInteractionEnabled = false
        scrollView.addSubview(rightMaskView)
        
        tailorHandler.frame = bounds
        tailorHandler.delegate = self
        tailorHandler.lineWidth = 3.0
        tailorHandler.lineColor = WhiteColor
        tailorHandler.normalColor = BlackColor
        tailorHandler.contentInset = contentInset
        tailorHandler.highlightedColor = WhiteColor
        addSubview(tailorHandler)
        
        pointer.frame = CGRect(x: 0.0, y: 0.0, width: 4.0, height: scrollView.frame.height)
        pointer.alpha = 0.0
        pointer.minX = scrollView.minX
        pointer.midY = scrollView.midY
        pointer.clipsToBounds = true
        pointer.layer.cornerRadius = pointer.frame.width/2.0
        pointer.layer.borderColor = UIColor.black.cgColor
        pointer.backgroundColor = .white
        pointer.layer.borderWidth = 0.8
        pointer.isUserInteractionEnabled = false
        addSubview(pointer)
        
        indicatorView.center = scrollView.center
        indicatorView.color = WhiteColor
        addSubview(indicatorView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData() {
        
        let videoPath: String = videoPath
        
        let duration: TimeInterval = MNAssetExporter.duration(mediaAtPath: videoPath)
        guard duration > minTailorDuration else {
            delegate?.tailorViewLoadThumbnailNotSatisfy(self)
            return
        }
        
        var naturalSize = MNAssetExporter.naturalSize(videoAtPath: videoPath)
        guard naturalSize != .zero else {
            delegate?.tailorViewLoadThumbnailsFailed(self)
            return
        }
        
        // 开始
        delegate?.tailorViewBeginLoadThumbnail(self)
        
        var contentSize: CGSize = scrollView.bounds.size
        let minTailorDuration: TimeInterval = max(1.0, min(minTailorDuration, duration - 1.0))
        let maxTailorDuration: TimeInterval = maxTailorDuration <= 0.0 ? duration : max(minTailorDuration, min(duration, maxTailorDuration))
        let ratio: CGFloat = max(1.0, duration/maxTailorDuration)
        let behavior: NSDecimalNumberHandler = NSDecimalNumberHandler(roundingMode: .plain, scale: 1, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let result: NSDecimalNumber = NSDecimalNumber(value: contentSize.width*ratio).dividing(by: NSDecimalNumber(value: 1.0), withBehavior: behavior)
        contentSize.width = CGFloat(result.floatValue)
        scrollView.contentSize = contentSize
        scrollView.setContentOffset(.zero, animated: false)
        thumbnailView.width = contentSize.width
        thumbnailView.contentSize = contentSize
        leftMaskView.contentSize = contentSize
        rightMaskView.contentSize = contentSize
        thumbnailView.alignment = .left
        leftMaskView.alignment = .left
        rightMaskView.alignment = .right
        adaptLeftMask()
        adaptRightMask()
        if ratio == 1.0 { scrollView.isUserInteractionEnabled = false }
        let widthByDuration: CGFloat = contentSize.width/duration
        let durationByWidth: TimeInterval = duration/contentSize.width
        tailorHandler.spacing = max(pointer.frame.width, ceil(minTailorDuration*widthByDuration))
        naturalSize = naturalSize.multiplyTo(height: contentSize.height)
        let thumbnailCount: Int = Int(ceil(duration/(durationByWidth*naturalSize.width)))
        naturalSize.width *= UIScreen.main.scale
        naturalSize.height *= UIScreen.main.scale
        naturalSize.width = ceil(naturalSize.width)
        // 生成截图
        thumbnailView.alpha = 0.0
        indicatorView.startAnimating()
        DispatchQueue.global().async { [weak self] in
            var thumbnails: [UIImage] = [UIImage]()
            let videoAsset: AVURLAsset = AVURLAsset(url: URL(fileURLWithPath: videoPath), options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
            let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: videoAsset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            generator.maximumSize = naturalSize
            for idx in 0..<thumbnailCount {
                let progress: Double = Double(idx)/Double(thumbnailCount)
                var imageRef: CGImage
                do {
                    imageRef = try generator.copyCGImage(at: CMTimeMultiplyByFloat64(videoAsset.duration, multiplier: progress), actualTime: nil)
                } catch {
                    continue
                }
                let thumbnail: UIImage = UIImage(cgImage: imageRef)
                thumbnails.append(thumbnail)
            }
            // 制作截图
            var thumbnail: UIImage!
            var grayImage: UIImage!
            if thumbnails.count > 0 {
                // 拼接截图
                let first: UIImage = thumbnails.first!
                UIGraphicsBeginImageContextWithOptions(CGSize(width: first.size.width*CGFloat(thumbnails.count), height: first.size.height), false, 1.0)
                for (idx, image) in thumbnails.enumerated() {
                    image.draw(in: CGRect(x: image.size.width*CGFloat(idx), y: 0.0, width: image.size.width, height: image.size.height))
                }
                thumbnail = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                if let image = thumbnail {
                    // 裁剪图片
                    var thumbnailSize: CGSize = contentSize.multiplyTo(height: image.size.height)
                    thumbnailSize.width = min(ceil(thumbnailSize.width), image.size.width)
                    UIGraphicsBeginImageContext(thumbnailSize)
                    image.draw(in: CGRect(x: 0.0, y: 0.0, width: thumbnailSize.width, height: thumbnailSize.height))
                    thumbnail = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                }
                grayImage = thumbnail?.grayImage
                if grayImage == nil { thumbnail = nil }
            }
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let _ = thumbnail {
                    self.indicatorView.stopAnimating()
                    self.leftMaskView.image = grayImage
                    self.rightMaskView.image = grayImage
                    self.thumbnailView.image = thumbnail
                    UIView.animate(withDuration: self.AnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
                        guard let self = self else { return }
                        self.pointer.alpha = 1.0
                        self.thumbnailView.alpha = 1.0
                    } completion: { [weak self] _ in
                        guard let self = self else { return }
                        // 通知加载截图结束
                        self.delegate?.tailorViewDidEndLoadThumbnail(self)
                    }
                } else {
                    // 加载截图失败
                    let thumbnailLabel = UILabel(frame: self.scrollView.bounds)
                    thumbnailLabel.text = "加载截图失败"
                    thumbnailLabel.alpha = 0.0
                    thumbnailLabel.numberOfLines = 1
                    thumbnailLabel.textAlignment = .center
                    thumbnailLabel.backgroundColor = .clear
                    thumbnailLabel.textColor = self.BlackColor
                    thumbnailLabel.font = .systemFont(ofSize: 16.0, weight: .medium)
                    self.scrollView.addSubview(thumbnailLabel)
                    self.indicatorView.stopAnimating()
                    UIView.animate(withDuration: self.AnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) {
                        thumbnailLabel.alpha = 1.0
                    } completion: { [weak self] _ in
                        guard let self = self else { return }
                        // 通知加载截图结束
                        self.delegate?.tailorViewDidEndLoadThumbnail(self)
                    }
                }
            }
        }
    }
    
    private func adaptLeftMask() {
        let contentOffset = scrollView.contentOffset
        leftMaskView.width = max(0.0, max(tailorHandler.leftHandler.maxX - scrollView.minX, 0.0) + contentOffset.x)
    }
    
    private func adaptRightMask() {
        let contentSize = scrollView.contentSize
        let contentOffset = scrollView.contentOffset
        let width: CGFloat = contentSize.width - (contentOffset.x + scrollView.frame.width)
        rightMaskView.width = max(0.0, max(0.0, scrollView.maxX - tailorHandler.rightHandler.minX) + width)
        rightMaskView.maxX = contentSize.width
    }
    
    private func adaptPointer(location: CGPoint) {
        pointer.midX = location.x
        pointer.minX = max(pointer.minX, tailorHandler.leftHandler.maxX)
        pointer.maxX = min(pointer.maxX, tailorHandler.rightHandler.minX)
    }
}

// MARK: - UIScrollViewDelegate
extension MNVideoTailorView: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        status = .dragging
        UIView.animate(withDuration: AnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.pointer.alpha = 0.0
        }, completion: nil)
        delegate?.tailorViewBeginDragging(self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adaptLeftMask()
        adaptRightMask()
        guard status == .dragging else { return }
        delegate?.tailorViewDidDragging(self)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false else { return }
        scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView.isDragging == false else { return }
        status = .none
        pointer.minX = tailorHandler.leftHandler.frame.maxX
        UIView.animate(withDuration: AnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.pointer.alpha = 1.0
        }, completion: nil)
        delegate?.tailorViewDidEndDragging(self)
    }
}

// MARK: - MNTailorHandlerDelegate
extension MNVideoTailorView: MNTailorHandlerDelegate {
    
    func tailorLeftHandlerBeginDragging(_ tailorHandler: MNTailorHandler) {
        tailorHandler.setHighlighted(true, animated: true)
        UIView.animate(withDuration: AnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.pointer.alpha = 0.0
        }, completion: nil)
        delegate?.tailorViewLeftHandlerBeginDragging(self)
    }
    
    func tailorLeftHandlerDidDragging(_ tailorHandler: MNTailorHandler) {
        adaptLeftMask()
        delegate?.tailorViewLeftHandlerDidDragging(self)
    }
    
    func tailorLeftHandlerDidEndDragging(_ tailorHandler: MNTailorHandler) {
        adaptLeftMask()
        tailorHandler.adaptHighlighted(animated: true)
        pointer.minX = tailorHandler.leftHandler.frame.maxX
        UIView.animate(withDuration: AnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.pointer.alpha = 1.0
        }, completion: nil)
        delegate?.tailorViewLeftHandlerEndDragging(self)
    }
    
    func tailorRightHandlerBeginDragging(_ tailorHandler: MNTailorHandler) {
        tailorHandler.setHighlighted(true, animated: true)
        UIView.animate(withDuration: AnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.pointer.alpha = 0.0
        }, completion: nil)
        delegate?.tailorViewRightHandlerBeginDragging(self)
    }
    
    func tailorRightHandlerDidDragging(_ tailorHandler: MNTailorHandler) {
        adaptRightMask()
        delegate?.tailorViewRightHandlerDidDragging(self)
    }
    
    func tailorRightHandlerDidEndDragging(_ tailorHandler: MNTailorHandler) {
        adaptRightMask()
        tailorHandler.adaptHighlighted(animated: true)
        if pointer.minX < tailorHandler.leftHandler.maxX {
            pointer.minX = tailorHandler.leftHandler.maxX
        } else if pointer.maxX > tailorHandler.rightHandler.minX {
            pointer.maxX = tailorHandler.rightHandler.minX
        }
        UIView.animate(withDuration: AnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.pointer.alpha = 1.0
        }, completion: nil)
        delegate?.tailorViewRightHandlerEndDragging(self)
    }
}

// MARK: - Touch
extension MNVideoTailorView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        if tailorHandler.contentRect.contains(location) {
            status = .touching
            delegate?.tailorViewPointerBeginDragging(self)
            adaptPointer(location: location)
            delegate?.tailorViewPointerDidDragging(self)
        } else {
            status = .none
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard status == .touching else { return }
        guard let location = touches.first?.location(in: self) else { return }
        adaptPointer(location: location)
        delegate?.tailorViewPointerDidDragging(self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard status == .touching else { return }
        status = .none
        delegate?.tailorViewPointerDidEndDragging(self)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard status == .touching else { return }
        status = .none
    }
}
