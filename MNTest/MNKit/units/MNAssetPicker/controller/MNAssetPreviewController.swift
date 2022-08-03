//
//  MNAssetPreviewController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/2/4.
//  媒体资源预览控制器

import UIKit

@objc protocol MNAssetPreviewDelegate: NSObjectProtocol {
    @objc optional func update(asset: MNAsset) -> Void
    @objc optional func previewController(didScroll controller: MNAssetPreviewController) -> Void
    @objc optional func previewController(_ controller: MNAssetPreviewController, buttonTouchUpInside sender: UIControl) -> Void
    @objc optional func previewController(_ controller: MNAssetPreviewController, shouldShowSelectButton button: MNAssetSelectButton) -> Bool
}

class MNAssetPreviewController: UIViewController {
    /**事件*/
    struct PreviewEvent: OptionSet {
        // 返回
        static let select = PreviewEvent(rawValue: 1 << 1)
        // 选择
        static let done = PreviewEvent(rawValue: 1 << 2)
        
        let rawValue: Int
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    /**间隔*/
    private let itemInterSpacing: CGFloat = 15.0
    /**媒体数组*/
    private let assets: [MNAsset]
    /**配置信息*/
    private let options: MNAssetPickerOptions
    /**是否在销毁时删除本地资源文件*/
    var isCleanWhenDeinit: Bool = false
    /**外界定制功能*/
    var events: PreviewEvent = []
    /**事件代理*/
    weak var delegate: MNAssetPreviewDelegate?
    /**是否允许自动播放*/
    var isAllowsAutoPlaying: Bool = true
    /**当前展示的索引*/
    private(set) var displayIndex: Int = Int.min
    /**状态栏*/
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    /**底部选择视图*/
    private lazy var selectView: MNAssetSelectView = {
        let selectView = MNAssetSelectView(frame: CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: 100.0), assets: assets, config: options)
        selectView.maxY = view.bounds.height - MNAssetBrowserCell.ToolBarHeight
        selectView.delegate = self
        return selectView
    }()
    /**顶部导航*/
    private lazy var navView: UIView = {
        let navView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: MN_TOP_BAR_HEIGHT))
        navView.backgroundColor = .clear
        navView.contentMode = .scaleToFill //bottom_mask
        navView.image = MNAssetPicker.image(named: "top")
        navView.isUserInteractionEnabled = true
        let back = UIButton(type: .custom)
        back.frame = CGRect(x: 15.0, y: 0.0, width: 25.0, height: 25.0)
        back.midY = (navView.bounds.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT
        back.setBackgroundImage(MNAssetPicker.image(named: "back"), for: .normal)
        back.addTarget(self, action: #selector(back(_:)), for: .touchUpInside)
        navView.addSubview(back)
        var right: CGFloat = navView.bounds.width - 15.0
        if events.contains(.done) {
            let done = UIButton(type: .custom)
            done.tag = PreviewEvent.done.rawValue
            done.frame = CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0)
            done.maxX = navView.bounds.width - right
            done.midY = (navView.bounds.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT
            done.setTitle("确定", for: .normal)
            done.titleLabel?.font = .systemFont(ofSize: 15.0)
            done.sizeToFit()
            done.width += 15.0
            done.height = 30.0
            done.contentVerticalAlignment = .center
            done.contentHorizontalAlignment = .center
            done.addTarget(self, action: #selector(buttonTouchUpInside(_:)), for: .touchUpInside)
            navView.addSubview(done)
            right = done.minX - 15.0
        }
        if events.contains(.select) {
            let select = MNAssetSelectButton(frame: CGRect(x: 0.0, y: 0.0, width: 25.0, height: 25.0), options: options)
            select.maxX = right
            select.midY = (navView.bounds.height - MN_STATUS_BAR_HEIGHT)/2.0 + MN_STATUS_BAR_HEIGHT
            select.isSelected = true
            select.tag = PreviewEvent.select.rawValue
            select.addTarget(self, action: #selector(update(asset:)), for: .touchUpInside)
            navView.addSubview(select)
        }
        return navView
    }()
    /**集合视图*/
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = itemInterSpacing
        layout.minimumInteritemSpacing = 0.0
        layout.headerReferenceSize = .zero
        layout.footerReferenceSize = .zero
        layout.itemSize = view.bounds.size
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: itemInterSpacing/2.0, bottom: 0.0, right: itemInterSpacing/2.0)
        let collectionView = UICollectionView(frame: view.bounds.inset(by: UIEdgeInsets(top: 0.0, left: -itemInterSpacing/2.0, bottom: 0.0, right: -itemInterSpacing/2.0)), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.scrollsToTop = false
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.delaysContentTouches = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.canCancelContentTouches = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(MNAssetBrowserCell.self, forCellWithReuseIdentifier: "com.mn.asset.preview.cell")
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never;
        }
        return collectionView
    }()
    
    init(assets: [MNAsset], options: MNAssetPickerOptions) {
        self.assets = assets
        self.options = options
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        guard isCleanWhenDeinit else { return }
        for asset in assets.filter({ $0.content != nil }) {
            asset.content = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .black
        
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        automaticallyAdjustsScrollViewInsets = false
        if #available(iOS 11.0, *) {
            additionalSafeAreaInsets = .zero
        }
        
        // 集合视图
        view.addSubview(collectionView)
        collectionView.reloadData()
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        // 底部选择视图
        if assets.count > 1 {
            view.addSubview(selectView)
        }
        // 导航
        view.addSubview(navView)
        // 事件
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(double(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(single(recognizer:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        view.addGestureRecognizer(singleTap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if displayIndex == Int.min {
            updateCurrentIndex()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cellForItemAtCurrent()?.endDisplaying()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension MNAssetPreviewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { assets.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "com.mn.asset.preview.cell", for: indexPath)
        (cell as? MNAssetBrowserCell)?.isAllowsAutoPlaying = isAllowsAutoPlaying
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay c: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = c as? MNAssetBrowserCell, indexPath.item < assets.count else { return }
        let asset = assets[indexPath.item]
        cell.update(asset: asset)
        cell.updateToolBar(visible: navView.frame.minY >= 0.0, animated: false)
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

// MARK: - 当前索引
private extension MNAssetPreviewController {
    
    func updateCurrentIndex() {
        let currentIndex: Int = Int(floor(collectionView.contentOffset.x/collectionView.bounds.width))
        if currentIndex == displayIndex { return }
        displayIndex = currentIndex
        if assets.count > 1 { selectView.update(selectIndex: displayIndex) }
        delegate?.previewController?(didScroll: self)
        cellForItemAtCurrent()?.beginDisplaying()
        guard displayIndex < assets.count, events.contains(.select), let button = navView.viewWithTag(PreviewEvent.select.rawValue) as? MNAssetSelectButton else { return }
        button.isSelected = assets[displayIndex].isSelected
        let isShow = delegate?.previewController?(self, shouldShowSelectButton: button) ?? true
        guard button.isHidden == isShow else { return }
        button.isHidden = isShow == false
        let add = isShow ? -(button.bounds.width + 15.0) : (button.bounds.width + 15.0)
        for subview in navView.subviews {
            guard subview is UIButton, subview.tag > PreviewEvent.select.rawValue, subview.frame.maxX <= button.frame.maxX else { continue }
            subview.maxX += add
        }
    }
    
    func cellForItemAtCurrent() -> MNAssetBrowserCell? {
        return collectionView.cellForItem(at: IndexPath(item: displayIndex, section: 0)) as? MNAssetBrowserCell
    }
}

// MARK: - 手势交互
extension MNAssetPreviewController {
    
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
        if navView.frame.minY >= 0 {
            let location = recognizer.location(in: view)
            guard view.bounds.inset(by: UIEdgeInsets(top: navView.frame.maxY, left: 0.0, bottom: 0.0, right: 0.0)).contains(location) else { return }
            if assets.count > 1 {
                guard view.bounds.inset(by: UIEdgeInsets(top: selectView.frame.minY, left: 0.0, bottom: view.bounds.height - selectView.frame.maxY, right: 0.0)).contains(location) == false else { return }
            }
        }
        guard let cell = cellForItemAtCurrent() else { return }
        let location = recognizer.location(in: cell.scrollView.contentView)
        guard cell.scrollView.contentView.bounds.contains(location) else { return }
        let isHidden = navView.frame.maxY <= 0.0
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.navView.minY = isHidden ? 0.0 : -self.navView.bounds.height
            if self.assets.count > 1 { self.selectView.alpha = isHidden ? 1.0 : 0.0 }
        }, completion: nil)
        cellForItemAtCurrent()?.updateToolBar(visible: isHidden, animated: true)
    }
}

// MARK: - Event
extension MNAssetPreviewController {
    
    @objc private func back(_ sender: UIControl) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func update(asset sender: UIControl) {
        guard displayIndex < assets.count, let button = sender as? MNAssetSelectButton else { return }
        let asset = assets[displayIndex]
        delegate?.update?(asset: asset)
        button.isSelected = asset.isSelected
    }
    
    @objc private func buttonTouchUpInside(_ sender: UIControl) {
        delegate?.previewController?(self, buttonTouchUpInside: sender)
    }
}

// MARK: - MNAssetSelectViewDelegate
extension MNAssetPreviewController: MNAssetSelectViewDelegate {
    
    func selectView(_ selectView: MNAssetSelectView, didSelectItemAtIndex selectIndex: Int) {
        guard selectIndex != displayIndex else { return }
        collectionView.scrollToItem(at: IndexPath(item: selectIndex, section: 0), at: .centeredHorizontally, animated: false)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
            self?.updateCurrentIndex()
        }
    }
}

// MARK: - 屏幕旋转
extension MNAssetPreviewController {
    override var shouldAutorotate: Bool { false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
}
