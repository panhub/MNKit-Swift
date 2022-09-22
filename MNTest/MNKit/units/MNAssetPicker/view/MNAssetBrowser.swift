//
//  MNAssetBrowser.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/10/8.
//  资源浏览器

import UIKit
import CoreAudio
import CoreMedia

@objc protocol MNAssetBrowseDelegate: NSObjectProtocol {
    @objc optional func assetBrowser(willPresent browser: MNAssetBrowser) -> Void
    @objc optional func assetBrowser(didPresent browser: MNAssetBrowser) -> Void
    @objc optional func assetBrowser(willDismiss browser: MNAssetBrowser) -> Void
    @objc optional func assetBrowser(didDismiss browser: MNAssetBrowser) -> Void
    @objc optional func assetBrowser(didScroll browser: MNAssetBrowser) -> Void
    @objc optional func assetBrowser(_ browser: MNAssetBrowser, buttonTouchUpInside sender: UIControl) -> Void
}

class MNAssetBrowser: UIView {
    /**事件*/
    struct BrowseEvent: OptionSet {
        // 返回
        static let back = BrowseEvent(rawValue: 1 << 1)
        // 确定
        static let done = BrowseEvent(rawValue: 1 << 2)
        // 保存
        static let save = BrowseEvent(rawValue: 1 << 3)
        // 分享
        static let share = BrowseEvent(rawValue: 1 << 4)
        
        let rawValue: Int
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    /**资源集合*/
    private var assets: [MNAsset] = []
    /**右按钮功能区*/
    var events: BrowseEvent = []
    /**资源选择器配置信息*/
    var options: MNAssetPickerOptions?
    /**是否允许自动播放*/
    var isAllowsAutoPlaying: Bool = true
    /**是否显示状态栏*/
    var isStatusBarHidden: Bool = false
    /**是否在销毁时删除本地资源文件*/
    var isCleanWhenDeinit: Bool = false
    /**是否在点击时退出*/
    var isAllowsDismissWhenTapped: Bool = false
    /**是否在下拉时退出*/
    var isAllowsDismissWhenPulled: Bool = true
    /**指定状态栏样式*/
    var statusBarStyle: UIStatusBarStyle = .lightContent
    /**状态栏更新回调*/
    var statusBarUpdateHandler: ((UIStatusBarStyle, Bool, Bool)->Void)?
    /**事件代理*/
    weak var delegate: MNAssetBrowseDelegate?
    /**当前展示的索引*/
    private(set) var displayIndex: Int = Int.min
    /**状态栏原本样式*/
    private var statusBarOriginalStyle: UIStatusBarStyle = .default
    /**状态栏原本是否隐藏*/
    private var statusBarOriginalHidden: Bool = false
    /**记录第一次截图*/
    private var lastBackgroundImage: UIImage?
    /**记录退出时的目标视图*/
    private var interactiveToView: UIView!
    /**记录交互视图的初始位置*/
    private var interactiveFrame: CGRect = .zero
    /**记录交互数据*/
    private var interactiveDelay: CGFloat = 0.0
    /**记录交互比例*/
    private var interactiveRatio: CGPoint = .zero
    /**是否允许缩放退出*/
    private var isAllowsZoomInteractive: Bool = false
    /**起始视图*/
    private var fromView: UIView!
    /**起始索引*/
    private var initialDisplayIndex: Int = 0
    /**右按钮集合*/
    private var items: [UIControl] = [UIControl]()
    /**间隔*/
    private static let interItemSpacing: CGFloat = 14.0
    /**展示动画时间间隔*/
    private static let presentAnimationDuration: TimeInterval = 0.28
    /**退出动画时间间隔*/
    private static let dismissAnimationDuration: TimeInterval = 0.46
    /**背景颜色图*/
    private lazy var animationView: UIImageView = {
        let animationView = UIImageView(frame: bounds)
        animationView.contentMode = .scaleAspectFill
        animationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return animationView
    }()
    /**背景图*/
    private lazy var backgroundView: UIImageView = {
        let backgroundView = UIImageView(frame: bounds)
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return backgroundView
    }()
    /**交互视图*/
    private lazy var interactiveView: UIImageView = {
        let interactiveView = UIImageView(frame: .zero)
        interactiveView.clipsToBounds = true
        interactiveView.contentMode = .scaleAspectFill
        interactiveView.isUserInteractionEnabled = false
        return interactiveView
    }()
    /**资源浏览*/
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = MNAssetBrowser.interItemSpacing
        layout.minimumInteritemSpacing = 0.0
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: MNAssetBrowser.interItemSpacing/2.0, bottom: 0.0, right: MNAssetBrowser.interItemSpacing/2.0)
        layout.footerReferenceSize = .zero
        layout.headerReferenceSize = .zero
        layout.scrollDirection = .horizontal
        layout.itemSize = bounds.size
        let collectionView = UICollectionView(frame: bounds.inset(by: UIEdgeInsets(top: 0.0, left: -MNAssetBrowser.interItemSpacing/2.0, bottom: 0.0, right: -MNAssetBrowser.interItemSpacing/2.0)), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.scrollsToTop = false
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.delaysContentTouches = false
        collectionView.canCancelContentTouches = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never;
        }
        collectionView.register(MNAssetBrowserCell.self, forCellWithReuseIdentifier: "com.mn.asset.browser.cell")
        return collectionView
    }()
    /**顶部阴影*/
    private lazy var navView: UIImageView = {
        let navView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: MN_TOP_BAR_HEIGHT))
        navView.alpha = 0.0
        navView.backgroundColor = .clear
        if events.contains(.back) {
            let back = UIButton(type: .custom)
            back.tag = BrowseEvent.back.rawValue
            back.frame = CGRect(x: 15.0, y: 0.0, width: 25.0, height: 25.0)
            back.midY = (navView.bounds.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT
            back.setBackgroundImage(MNAssetPicker.image(named: "back"), for: .normal)
            back.addTarget(self, action: #selector(back(_:)), for: .touchUpInside)
            navView.addSubview(back)
        }
        var right: CGFloat = navView.bounds.width - 15.0
        if events.contains(.done) {
            let done = UIButton(type: .custom)
            done.tag = BrowseEvent.done.rawValue
            done.frame = CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0)
            done.maxX = right
            done.midY = (navView.bounds.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT
            done.setBackgroundImage(MNAssetPicker.image(named: "done"), for: .normal)
            done.addTarget(self, action: #selector(buttonTouchUpInside(_:)), for: .touchUpInside)
            navView.addSubview(done)
            right = done.minX - 15.0
        }
        if events.contains(.save) {
            let save = UIButton(type: .custom)
            save.tag = BrowseEvent.save.rawValue
            save.frame = CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0)
            save.maxX = right
            save.midY = (navView.bounds.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT
            save.setBackgroundImage(MNAssetPicker.image(named: "save"), for: .normal)
            save.addTarget(self, action: #selector(buttonTouchUpInside(_:)), for: .touchUpInside)
            navView.addSubview(save)
            right = save.minX - 15.0
        }
        if events.contains(.share) {
            let share = UIButton(type: .custom)
            share.tag = BrowseEvent.share.rawValue
            share.frame = CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0)
            share.maxX = right
            share.midY = (navView.bounds.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT
            share.setBackgroundImage(MNAssetPicker.image(named: "share"), for: .normal)
            share.addTarget(self, action: #selector(buttonTouchUpInside(_:)), for: .touchUpInside)
            navView.addSubview(share)
            right = share.minX - 15.0
        }
        if navView.subviews.count > 0 {
            navView.contentMode = .scaleToFill
            navView.isUserInteractionEnabled = true
            navView.image = MNAssetPicker.image(named: "top")
        }
        return navView
    }()
    
    private override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        NotificationCenter.default.addObserver(self, selector: #selector(removeFromSuperview), name: MNAlertQueue.closeAlertViewNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(assets: [MNAsset]) {
        super.init(frame: UIScreen.main.bounds)
        self.assets.append(contentsOf: assets)
        if #available(iOS 13.0, *) {
            if let statusBarManager = UIApplication.shared.delegate?.window??.windowScene?.statusBarManager {
                statusBarOriginalStyle = statusBarManager.statusBarStyle
                statusBarOriginalHidden = statusBarManager.isStatusBarHidden
            }
        } else {
            statusBarOriginalStyle = UIApplication.shared.statusBarStyle
            statusBarOriginalHidden = UIApplication.shared.isStatusBarHidden
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        guard isCleanWhenDeinit else { return }
        for asset in assets.filter({ $0.content != nil }) {
            asset.content = nil
        }
    }
    
    private func createView() {
        addSubview(backgroundView)
        addSubview(animationView)
        addSubview(collectionView)
        addSubview(interactiveView)
        addSubview(navView)
    }
    
    private func addEvent() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(double(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        if isAllowsDismissWhenTapped {
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(single(recognizer:)))
            singleTap.delegate = self
            singleTap.numberOfTapsRequired = 1
            singleTap.require(toFail: doubleTap)
            addGestureRecognizer(singleTap)
        }
        if isAllowsDismissWhenPulled {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(recognizer:)))
            addGestureRecognizer(pan)
        }
    }
}

// MARK: - 弹出
extension MNAssetBrowser {
    func present(in view: UIView? = nil, from index: Int = 0, animated: Bool = true, completion: (()->Void)? = nil) {
        // 保证资源模型可用
        guard assets.count > 0, index < assets.count else {
            fatalError("unknown assets.")
        }
        
        let asset = assets[index]
        guard let container = asset.container else {
            fatalError("unknown from asset container.")
        }
        
        var animatedImage: UIImage?
        if let thumbnail = asset.thumbnail {
            animatedImage = thumbnail
        } else if container is UIImageView, let imageView = container as? UIImageView {
            animatedImage = imageView.image
        } else if container is UIButton, let button = container as? UIButton {
            animatedImage = button.currentBackgroundImage
            if animatedImage == nil { animatedImage = button.currentImage }
        } else if let content = asset.content, content is UIImage, let image = content as? UIImage {
            animatedImage = image
        }
        if let images = animatedImage?.images, images.count > 1 { animatedImage = images.first }
        
        guard let _ = animatedImage else {
            #if DEBUG
            print("unknown from asset thumbnail.")
            #endif
            return
        }
        
        guard let superview = (view ?? UIWindow.current) else {
            #if DEBUG
            print("unknown from superview.")
            #endif
            return
        }
        
        let isUserInteractionEnabled = superview.isUserInteractionEnabled
        superview.isUserInteractionEnabled = false
        center = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)
        
        let backgroundColor = self.backgroundColor
        self.backgroundColor = .clear
        
        let fromView = container
        self.fromView = fromView
        self.initialDisplayIndex = index
        
        fromView.isHidden = true
        backgroundView.image = superview.layer.snapshot
        fromView.isHidden = false
        
        createView()
        addEvent()
        superview.addSubview(self)
        
        collectionView.isHidden = true
        collectionView.reloadData()
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
        
        animationView.alpha = 0.0
        animationView.image = UIImage(color: backgroundColor ?? .black, size: animationView.bounds.size)
        
        let targetSize = animatedImage!.size.scaleAspectFit(toSize: bounds.size)
        let toRect = CGRect(x: (self.bounds.width - targetSize.width)/2.0, y: (self.bounds.height - targetSize.height)/2.0, width: targetSize.width, height: targetSize.height)
        
        interactiveView.image = animatedImage
        interactiveView.frame = fromView.superview!.convert(fromView.frame, to: self)
        interactiveView.layer.cornerRadius = fromView.layer.cornerRadius
        interactiveView.contentMode = fromView.contentMode
        
        delegate?.assetBrowser?(willPresent: self)
        
        UIView.setAnimationsEnabled(true)
        statusBarUpdateHandler?(statusBarStyle, isStatusBarHidden, animated)
        let animationDuration: TimeInterval = animated ? MNAssetBrowser.presentAnimationDuration : 0.0
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            self.navView.alpha = 1.0
            self.animationView.alpha = 1.0
            self.interactiveView.frame = toRect
            self.interactiveView.layer.setValue(0.0, forKey: "cornerRadius")
        } completion: { [weak self, weak superview] _ in
            guard let self = self else { return }
            self.collectionView.isHidden = false
            self.interactiveView.isHidden = true
            superview?.isUserInteractionEnabled = isUserInteractionEnabled
            completion?()
            self.delegate?.assetBrowser?(didPresent: self)
            self.updateCurrentIndex()
        }
    }
    
    static func present(container: UIView, using image: UIImage? = nil, animated: Bool = true, completion: (()->Void)? = nil) {
        var animatedImage: UIImage? = image
        if animatedImage == nil {
            if container is UIImageView, let imageView = container as? UIImageView {
                animatedImage = imageView.image
            } else if container is UIButton, let button = container as? UIButton {
                animatedImage = button.currentBackgroundImage
                if animatedImage == nil { animatedImage = button.currentImage }
            }
            if let images = animatedImage?.images, images.count > 1 { animatedImage = images.first }
        }
        guard let _ = animatedImage else {
            fatalError("unknown animated image.")
        }
        guard let asset = MNAsset(content: animatedImage!, options: nil) else {
            fatalError("unknown asset.")
        }
        asset.container = container
        let browser = MNAssetBrowser(assets: [asset])
        browser.isStatusBarHidden = true
        browser.backgroundColor = .black
        browser.present(animated: animated, completion: completion)
    }
}

// MARK: - 消失
extension MNAssetBrowser {
    func dismiss(animated: Bool = true, completion: (()->Void)? = nil) {
        
        let superview = superview!
        let isUserInteractionEnabled = superview.isUserInteractionEnabled
        superview.isUserInteractionEnabled = false
        
        let asset = assets[displayIndex]
        var toView: UIView! = displayIndex == initialDisplayIndex ? fromView : asset.container
        if let view = toView, view != fromView {
            let rect = convert(view.frame, from: view.superview!)
            if bounds.intersects(rect) == false { toView = fromView }
        }
        if toView == nil { toView = fromView }
        if toView! != fromView {
            // 重新截屏
            isHidden = true
            toView!.isHidden = true
            backgroundView.image = superview.layer.snapshot
            isHidden = false
            toView!.isHidden = false
        }
        
        let cell = cellForItemAtCurrent()
        cell?.pauseDisplaying()
        
        var animatedImage: UIImage?
        if let thumbnail = asset.thumbnail {
            animatedImage = thumbnail
        } else if toView is UIImageView, let imageView = toView as? UIImageView {
            animatedImage = imageView.image
        } else if toView is UIButton, let button = toView as? UIButton {
            animatedImage = button.currentBackgroundImage
            if animatedImage == nil { animatedImage = button.currentImage }
        } else if let _ = cell {
            animatedImage = cell!.currentImage
        }
        if let images = animatedImage?.images, images.count > 1 { animatedImage = images.first }
        
        collectionView.isHidden = true
        interactiveView.isHidden = false
        interactiveView.image = animatedImage
        interactiveView.contentMode = toView.contentMode
        interactiveView.frame = convert(cell!.scrollView.contentView.frame, from: cell!.scrollView)
        
        delegate?.assetBrowser?(willDismiss: self)
        
        UIView.setAnimationsEnabled(true)
        statusBarUpdateHandler?(statusBarOriginalStyle, statusBarOriginalHidden, animated)
        let cornerRadius = toView?.layer.cornerRadius ?? 0.0
        let toRect = convert(toView!.frame, from: toView!.superview!)
        let animationDuration: TimeInterval = animated ? MNAssetBrowser.dismissAnimationDuration : 0.0
        UIView.animate(withDuration: animationDuration) { [weak self] in
            guard let self = self else { return }
            self.animationView.alpha = 0.0
        }
        UIView.animate(withDuration: animationDuration/2.0, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            self.interactiveView.frame = toRect
            self.interactiveView.layer.setValue(0.99, forKey: "transform.scale")
            self.interactiveView.layer.setValue(cornerRadius, forKey: "cornerRadius")
        } completion: { [weak self, weak superview] _ in
            UIView.animate(withDuration: animationDuration/2.0, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) {
                guard let self = self else { return }
                self.alpha = 0.0
                self.interactiveView.layer.setValue(1.0, forKey: "transform.scale")
            } completion: { _ in
                guard let self = self else { return }
                self.removeFromSuperview()
                superview?.isUserInteractionEnabled = isUserInteractionEnabled
                completion?()
                self.delegate?.assetBrowser?(didDismiss: self)
            }
        }
    }
}

// MARK: - 当前索引
private extension MNAssetBrowser {
    
    func updateCurrentIndex() {
        let currentIndex: Int = Int(floor(collectionView.contentOffset.x/collectionView.bounds.width))
        if currentIndex == displayIndex { return }
        displayIndex = currentIndex
        delegate?.assetBrowser?(didScroll: self)
        cellForItemAtCurrent()?.beginDisplaying()
    }
    
    func cellForItemAtCurrent() -> MNAssetBrowserCell? {
        return collectionView.cellForItem(at: IndexPath(item: displayIndex, section: 0)) as? MNAssetBrowserCell
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension MNAssetBrowser: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "com.mn.asset.browser.cell", for: indexPath)
        (cell as? MNAssetBrowserCell)?.isAllowsAutoPlaying = isAllowsAutoPlaying
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay c: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = c as? MNAssetBrowserCell, indexPath.item < assets.count else { return }
        let asset = assets[indexPath.item]
        cell.update(asset: asset)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? MNAssetBrowserCell)?.endDisplaying()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false, scrollView.isDragging == false, scrollView.isDecelerating == false else { return }
        updateCurrentIndex()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentIndex()
    }
}

// MARK: - Event
extension MNAssetBrowser {
    
    @objc private func back(_ sender: UIControl) {
        if let cell = cellForItemAtCurrent(), cell.scrollView.zoomScale > 1.0 {
            cell.scrollView.setZoomScale(1.0, animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func buttonTouchUpInside(_ sender: UIControl) {
        delegate?.assetBrowser?(self, buttonTouchUpInside: sender)
    }
}

// MARK: - 交互
extension MNAssetBrowser: UIGestureRecognizerDelegate {
    @objc func double(recognizer: UITapGestureRecognizer) {
        guard let cell = cellForItemAtCurrent() else { return }
        let location = recognizer.location(in: cell.scrollView.contentView)
        guard cell.scrollView.contentView.bounds.contains(location) else { return }
        if cell.scrollView.zoomScale > 1.0 {
            cell.scrollView.setZoomScale(1.0, animated: true)
        } else {
            let scale = cell.scrollView.maximumZoomScale
            let width = cell.scrollView.bounds.width/scale
            let height = cell.scrollView.bounds.height/scale
            cell.scrollView.zoom(to: CGRect(x: location.x - width/2.0, y: location.y - height/2.0, width: width, height: height), animated: true)
        }
    }
    @objc func single(recognizer: UITapGestureRecognizer) {
        guard let cell = cellForItemAtCurrent(), cell.scrollView.zoomScale == 1.0 else { return }
        let location = recognizer.location(in: cell.scrollView.contentView)
        guard cell.scrollView.contentView.bounds.contains(location) else { return }
        dismiss(animated: true, completion: nil)
    }
    @objc func pan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            
            guard let cell = cellForItemAtCurrent(), cell.scrollView.zoomScale <= 1.0 else { return }
            let location = recognizer.location(in: cell.scrollView.contentView)
            guard cell.scrollView.contentView.bounds.contains(location) else { return }
            
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.navView.alpha = 0.0
            }
            
            cell.pauseDisplaying()
            
            let asset = assets[displayIndex]
            var interactiveToView: UIView? = displayIndex == initialDisplayIndex ? fromView : asset.container
            if let view = interactiveToView, view != fromView {
                let rect = convert(view.frame, from: view.superview!)
                if bounds.intersects(rect) == false { interactiveToView = fromView }
            }
            if interactiveToView == nil { interactiveToView = fromView }
            if interactiveToView! != fromView {
                // 重新截屏
                isHidden = true
                interactiveToView!.isHidden = true
                lastBackgroundImage = backgroundView.image
                backgroundView.image = superview?.layer.snapshot
                isHidden = false
                interactiveToView!.isHidden = false
            }
            self.interactiveToView = interactiveToView
            
            collectionView.isHidden = true
            interactiveView.isHidden = false
            interactiveView.image = cell.currentImage
            interactiveView.frame = convert(cell.scrollView.contentView.frame, from: cell.scrollView)
            interactiveFrame = interactiveView.frame
            
            var toSize = interactiveToView!.bounds.size
            if toSize.width > bounds.size.width || toSize.height > bounds.size.height { toSize = toSize.scaleAspectFit(toSize: bounds.size) }
            interactiveDelay = (bounds.height - toSize.height)/2.0
            interactiveRatio = CGPoint(x: toSize.width/interactiveFrame.width, y: toSize.height/interactiveFrame.height)
            isAllowsZoomInteractive = max(bounds.width, bounds.height) - max(interactiveView.bounds.width, interactiveView.bounds.height) >= 50.0

        case .changed:
            
            guard interactiveView.isHidden == false else { return }
            
            let ratio = abs(bounds.height/2.0 - interactiveView.frame.midY)/interactiveDelay
            
            let translation = recognizer.translation(in: self)
            recognizer.setTranslation(.zero, in: self)
            
            var center = interactiveView.center
            center.y += translation.y
            
            if isAllowsZoomInteractive {
                center.x += translation.x
                var rect = interactiveFrame
                rect.size.width = (1.0 - (1.0 - self.interactiveRatio.x)*ratio)*rect.width
                rect.size.height = (1.0 - (1.0 - self.interactiveRatio.y)*ratio)*rect.height
                rect.origin.x = center.x - rect.width/2.0
                rect.origin.y = center.y - rect.height/2.0
                rect.origin.x = min(max(0.0, rect.minX), bounds.width - rect.width)
                rect.origin.y = min(max(0.0, rect.minY), bounds.height - rect.height)
                interactiveView.frame = rect
            } else {
                interactiveView.center = center
                var rect = interactiveView.frame
                rect.origin.y = min(bounds.height, max(-rect.height, rect.minY))
                interactiveView.frame = rect
            }
            
            animationView.alpha = 1.0 - ratio*0.8
            
        case .ended:
            
            guard interactiveView.isHidden == false else { return }
            
            if interactiveView.frame.midY >= (bounds.midY + 50.0) {
                dismissFromCurrent()
            } else {
                endPanFromCurrent()
            }
        case .cancelled:
            guard interactiveView.isHidden == false else { return }
            endPanFromCurrent()
        default:
            break
        }
    }
    
    func dismissFromCurrent() {
        let superview = superview!
        let isUserInteractionEnabled = superview.isUserInteractionEnabled
        superview.isUserInteractionEnabled = false
        
        var toRect = interactiveView.frame
        var cornerRadius = interactiveView.layer.cornerRadius
        var contentMode = interactiveView.contentMode
        if isAllowsZoomInteractive, let _ = interactiveToView {
            contentMode = interactiveToView!.contentMode
            cornerRadius = interactiveToView!.layer.cornerRadius
            toRect = convert(interactiveToView!.frame, from: interactiveToView!.superview!)
        } else {
            toRect.origin.y = interactiveView.frame.minY < 0.0 ? -toRect.height : bounds.height
        }
        interactiveView.contentMode = contentMode
        
        delegate?.assetBrowser?(willDismiss: self)
        
        UIView.setAnimationsEnabled(true)
        statusBarUpdateHandler?(statusBarOriginalStyle, statusBarOriginalHidden, true)
        UIView.animate(withDuration: MNAssetBrowser.dismissAnimationDuration) { [weak self] in
            guard let self = self else { return }
            self.animationView.alpha = 0.0
        }
        UIView.animate(withDuration: MNAssetBrowser.dismissAnimationDuration/2.0, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            self.interactiveView.frame = toRect
            self.interactiveView.layer.setValue(cornerRadius, forKey: "cornerRadius")
        } completion: { [weak self, weak superview] _ in
            UIView.animate(withDuration: MNAssetBrowser.dismissAnimationDuration/2.0) {
                guard let self = self else { return }
                self.alpha = 0.0
            } completion: { _ in
                guard let self = self else { return }
                self.removeFromSuperview()
                superview?.isUserInteractionEnabled = isUserInteractionEnabled
                self.delegate?.assetBrowser?(didDismiss: self)
            }
        }
    }
    
    func endPanFromCurrent() {
        UIView.animate(withDuration: MNAssetBrowser.dismissAnimationDuration/2.0, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            self.navView.alpha = 1.0
            self.animationView.alpha = 1.0
            self.interactiveView.frame = self.interactiveFrame
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.collectionView.isHidden = false
            self.interactiveView.isHidden = true
            if let _ = self.lastBackgroundImage {
                self.backgroundView.image = self.lastBackgroundImage
                self.lastBackgroundImage = nil
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool { true }
}
