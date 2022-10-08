//
//  MNAssetPickerController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/27.
//  资源挑选控制器

import UIKit
import Photos

class MNAssetPickerController: UIViewController {
    /**空视图*/
    private lazy var emptyView: MNEmptyView = {
        let emptyView = MNEmptyView(frame: view.bounds.inset(by: options.contentInset))
        emptyView.alignment = .top
        emptyView.contentOffset = UIOffset(horizontal: 0.0, vertical: 120.0)
        emptyView.imageSize = CGSize(width: 120.0, height: 120.0)
        emptyView.backgroundColor = options.backgroundColor
        emptyView.image = MNAssetPicker.image(named: "empty")
        return emptyView
    }()
    /**配置信息*/
    let options: MNAssetPickerOptions = MNAssetPickerOptions()
    /**选中的资源集合*/
    private var assets: [MNAsset] = [MNAsset]()
    /**选中的资源集合*/
    private var selecteds: [MNAsset] = [MNAsset]()
    /**相簿集合*/
    private var collections: [MNAssetAlbum] = [MNAssetAlbum]()
    /**上一次交互索引*/
    private var lastTouchIndex: Int = -1
    /**状态栏修改*/
    private lazy var statusBarStyle: UIStatusBarStyle = {
        return options.mode == .dark ? .lightContent : .default
    }()
    private var statusBarHidden: Bool = false
    override var prefersStatusBarHidden: Bool { statusBarHidden }
    override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }
    /**顶部栏*/
    private lazy var navBar: MNAssetPickerNavBar = {
        let navBar = MNAssetPickerNavBar(options: options)
        navBar.delegate = self
        return navBar
    }()
    /**相册视图*/
    private lazy var albumView: MNAssetAlbumView = {
        let albumView = MNAssetAlbumView(options: options)
        albumView.delegate = self
        return albumView
    }()
    /**底部工具栏*/
    private lazy var toolBar: MNAssetPickerToolBar = {
        let toolBar = MNAssetPickerToolBar(options: options)
        toolBar.delegate = self
        return toolBar
    }()
    /**资源展示*/
    private lazy var collectionView: UICollectionView = {
        let numberOfColumns: Int = max(options.numberOfColumns, 1)
        let itemWidth = floor((view.bounds.width - CGFloat(numberOfColumns - 1)*options.minimumInteritemSpacing)/CGFloat(numberOfColumns))
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = options.minimumLineSpacing
        layout.minimumInteritemSpacing = options.minimumInteritemSpacing
        layout.headerReferenceSize = .zero
        layout.footerReferenceSize = .zero
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.sectionInset = options.contentInset
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.scrollsToTop = false
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = options.backgroundColor
        collectionView.register(MNAssetCell.self, forCellWithReuseIdentifier: "com.mn.asset.picker.cell")
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never;
        }
        return collectionView
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = options.backgroundColor
        
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        if #available(iOS 11.0, *) {
            additionalSafeAreaInsets = .zero
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        view.addSubview(emptyView)
        view.addSubview(collectionView)
        view.addSubview(navBar)
        view.addSubview(albumView)
        view.addSubview(toolBar)
        
        if options.maxPickingCount > 1, options.isAllowsSlidePicking, options.isAllowsMultiplePickingPhoto, options.isAllowsMultiplePickingGif, options.isAllowsMultiplePickingVideo, options.isAllowsMultiplePickingLivePhoto {
            // 滑动选择
            collectionView.bounces = false
            let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(recognizer:)))
            pan.maximumNumberOfTouches = 1
            view.addGestureRecognizer(pan)
        }
        
        // 获取数据
        fetchAssets()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // 更新相册
    private func update(album: MNAssetAlbum) {
        // 处理不可选
        if album.assets.count > 0 {
            for asset in album.assets {
                asset.isEnabled = true
            }
            reload(assets: album.assets)
        }
        assets.removeAll()
        assets.append(contentsOf: album.assets)
        collectionView.reloadData()
        collectionView.isHidden = album.assets.count <= 0
        navBar.badge.update(title: album.title, animated: navBar.badge.isEnabled)
        if album.assets.count > 0, options.isSortAscending {
            let indexPath = IndexPath(item: album.assets.count - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }
    
    // 更新资源
    func update(asset: MNAsset) {
        if asset.isSelected {
            asset.isSelected = false
            if let index = selecteds.firstIndex(of: asset) {
                selecteds.remove(at: index)
            }
        } else {
            asset.isSelected = true
            selecteds.append(asset)
        }
        // 更新标记
        for (index, asset) in selecteds.enumerated() {
            asset.index = index + 1
        }
        reload(assets: assets)
        toolBar.update(assets: selecteds)
        collectionView.reloadData()
    }
    
    // 刷新指定数据状态
    private func reload(assets: [MNAsset]) {
        // 判断是否超过限制
        if selecteds.count >= options.maxPickingCount {
            // 标记不能再选择
            for asset in assets.filter({ $0.isSelected == false && $0.isEnabled }) {
                asset.isEnabled = false
            }
        } else {
            // 结束限制
            for asset in assets {
                asset.isEnabled = true
            }
            // 类型限制
            if selecteds.count > 0 {
                let type = selecteds.first!.type
                if options.isAllowsMixPicking == false {
                    for asset in assets.filter({ $0.isSelected == false && $0.type != type }) {
                        asset.isEnabled = false
                    }
                }
                // 检查限制(可不加)
                if type == .photo, options.isAllowsMultiplePickingPhoto == false {
                    for asset in assets.filter({ $0.isSelected == false && $0.type == .photo }) {
                        asset.isEnabled = false
                    }
                } else if type == .gif, options.isAllowsMultiplePickingGif == false {
                    for asset in assets.filter({ $0.isSelected == false && $0.type == .gif }) {
                        asset.isEnabled = false
                    }
                } else if type == .video, options.isAllowsMultiplePickingVideo == false {
                    for asset in assets.filter({ $0.isSelected == false && $0.type == .video }) {
                        asset.isEnabled = false
                    }
                } else if type == .livePhoto, options.isAllowsMultiplePickingLivePhoto == false {
                    for asset in assets.filter({ $0.isSelected == false && $0.type == .livePhoto }) {
                        asset.isEnabled = false
                    }
                }
            }
        }
    }
    
    /// 裁剪视频
    /// - Parameter asset: 视频资源模型
    private func tailorVideo(_ asset: MNAsset) {
        view.showActivityToast("请稍后")
        MNAssetHelper.content(asset: asset, progress: nil) { [weak self] ast in
            guard let self = self else { return }
            if let videoPath = ast.content as? String {
                ast.content = nil
                self.view.closeToast()
                let vc = MNTailorViewController(videoPath: videoPath)
                vc.delegate = self
                vc.exportingPath = self.options.outputURL?.path
                vc.minTailorDuration = self.options.minExportDuration
                vc.maxTailorDuration = self.options.maxExportDuration
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                self.view.showMsgToast("导出视频失败")
            }
        }
    }
    
    // 结束选择
    private func export(assets: [MNAsset]) {
        let view = navigationController?.view
        view?.isUserInteractionEnabled = false
        MNAssetHelper.export(assets: assets, options: options) { [weak view] index, count in
            DispatchQueue.main.async {
                view?.showActivityToast("正在导出\(index + 1)/\(count)")
            }
        } completion: { [weak self, weak view] result in
            DispatchQueue.main.async {
                view?.closeToast()
                view?.isUserInteractionEnabled = true
                guard let self = self else { return }
                if result.count == assets.count {
                    self.finishPicking(assets: result)
                } else if (result.count <= 0 || result.count < self.options.minPickingCount) {
                    // 低于最小数量
                    let alert = UIAlertController(title: nil, message: "iCloud资源下载失败!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                    alert.addAction(UIAlertAction(title: "重试", style: .default, handler: { [weak self] _ in
                        self?.export(assets: assets)
                    }))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // 有失败的
                    let alert = UIAlertController(title: nil, message: "\(assets.count - result.count)项资源导出失败!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                    alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] _ in
                        self?.finishPicking(assets: result)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func finishPicking(assets: [MNAsset]) {
        guard let picker = navigationController as? MNAssetPicker else { return }
        options.delegate?.assetPicker(picker, didFinishPicking: assets)
    }
}

// MARK: - 获取权限/加载数据
private extension MNAssetPickerController {
    private func fetchAssets() {
        let options = self.options
        collectionView.showActivityToast("请稍后")
        MNAuthorization.requestAlbum { [weak self] granted in
            if granted {
                // 请求数据
                MNAssetHelper.albums(options: options) { albums in
                    guard let self = self else { return }
                    self.collectionView.closeToast()
                    if albums.count > 0 {
                        albums.first!.isSelected = true
                        self.albumView.update(albums: albums)
                        self.navBar.badge.isEnabled = albums.count > 1
                        self.update(album: albums.first!)
                    } else {
                        self.collectionView.isHidden = true
                    }
                }
            } else {
                self?.collectionView.closeToast()
                self?.collectionView.isHidden = true
            }
        }
    }
}

// MARK: - PanGestureRecognizer
extension MNAssetPickerController {
    @objc func pan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            guard collectionView.isHidden == false else { return }
            let location = recognizer.location(in: view)
            guard view.bounds.inset(by: options.contentInset).contains(location) else { return }
            let point = view.convert(location, to: collectionView)
            guard let indexPath = collectionView.indexPathForItem(at: point), indexPath.item != lastTouchIndex, indexPath.item < assets.count else { return }
            lastTouchIndex = indexPath.item
            let asset = assets[indexPath.item]
            guard asset.isEnabled else { return }
            update(asset: asset)
        default:
            lastTouchIndex = -1
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension MNAssetPickerController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { assets.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "com.mn.asset.picker.cell", for: indexPath)
        (cell as? MNAssetCell)?.delegate = self
        (cell as? MNAssetCell)?.options = options
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? MNAssetCell)?.update(asset: assets[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? MNAssetCell)?.endDisplaying()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < assets.count else { return }
        let asset = assets[indexPath.item]
        guard asset.isEnabled else { return }
        if options.maxPickingCount <= 1 || (asset.type == .photo && options.isAllowsMultiplePickingPhoto == false) || (asset.type == .gif && options.isAllowsMultiplePickingGif == false) || (asset.type == .video && options.isAllowsMultiplePickingVideo == false) || (asset.type == .livePhoto && options.isAllowsMultiplePickingLivePhoto == false) {
            if asset.type == .photo, options.isAllowsEditing {
                // TODO 图片裁剪
            } else if asset.type == .video, options.isAllowsEditing {
                // 视频裁剪
                tailorVideo(asset)
            } else {
                // 导出
                export(assets: [asset])
            }
        } else {
            // 更新资源状态
            update(asset: asset)
        }
    }
}

// MARK: - MNTailorControllerDelegate
extension MNAssetPickerController: MNTailorControllerDelegate {
    
    func tailorControllerDidCancel(_ tailorController: MNTailorViewController) {
        tailorController.navigationController?.popViewController(animated: true)
    }
    
    func tailorController(_ tailorController: MNTailorViewController, didTailorVideoAtPath videoPath: String) {
        guard let asset = MNAsset(content: videoPath, options: options) else {
            try? FileManager.default.removeItem(atPath: videoPath)
            tailorController.view.showMsgToast("视频导出失败")
            return
        }
        finishPicking(assets: [asset])
    }
}

// MARK: - MNAssetCellDelegate
extension MNAssetPickerController: MNAssetCellDelegate {
    
    func assetCellShouldPreviewAsset(_ cell: MNAssetCell) {
        guard let asset = cell.asset, let _ = asset.thumbnail else {
            view.showMsgToast("暂无法预览")
            return
        }
        let browser = MNAssetBrowser(assets: [asset])
        browser.events = [.back]
        browser.backgroundColor = .black
        browser.isCleanWhenDeinit = true
        browser.statusBarStyle = .lightContent
        browser.dismissWhenPulled = true
        browser.statusBarUpdateHandler = { [weak self] style, hidden, animated in
            self?.statusBarStyle = style
            self?.statusBarHidden = hidden
            self?.setNeedsStatusBarAppearanceUpdate()
        }
        browser.present(in: view)
    }
}

// MARK: - MNAssetPickerNavDelegate
extension MNAssetPickerController: MNAssetPickerNavDelegate {
    
    func closeButtonTouchUpInside() {
        guard let picker = navigationController as? MNAssetPicker else { return }
        options.delegate?.assetPicker?(didCancel: picker)
    }
    
    func albumButtonTouchUpInside(_ badge: MNAssetAlbumBadge) {
        badge.isUserInteractionEnabled = false
        let isShow: Bool = badge.isSelected == false
        badge.isSelected = isShow
        let completionHandler: ()->Void = { [weak badge] in
            badge?.isUserInteractionEnabled = true
        }
        if isShow {
            albumView.show(completion: completionHandler)
        } else {
            albumView.dismiss(completion: completionHandler)
        }
    }
}

// MARK: - MNAssetPickerToolDelegate
extension MNAssetPickerController: MNAssetPickerToolDelegate {
    func previewButtonTouchUpInside(_ toolBar: MNAssetPickerToolBar) {
        let previewController = MNAssetPreviewController(assets: selecteds, options: options)
        previewController.isCleanWhenDeinit = true
        navigationController?.pushViewController(previewController, animated: true)
    }
    func clearButtonTouchUpInside(_ toolBar: MNAssetPickerToolBar) {
        let alert = UIAlertController(title: nil, message: "确定清空已选内容?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            for album in self.albumView.albums {
                for asset in album.assets.filter({ $0.isSelected || $0.isEnabled == false }) {
                    asset.isEnabled = true
                    asset.isSelected = false
                }
            }
            self.selecteds.removeAll()
            self.collectionView.reloadData()
            if self.albumView.isShow { self.albumView.reloadData() }
            if self.options.maxPickingCount > 1 { self.toolBar.update(assets: self.selecteds) }
        }))
        present(alert, animated: true, completion: nil)
    }
    func doneButtonTouchUpInside(_ toolBar: MNAssetPickerToolBar) {
        export(assets: selecteds)
    }
}

// MARK: - MNAssetAlbumViewDelegate
extension MNAssetPickerController: MNAssetAlbumViewDelegate {
    func albumView(_ albumView: MNAssetAlbumView, didSelectAlbum album: MNAssetAlbum?) {
        navBar.badge.isSelected = false
        navBar.badge.isUserInteractionEnabled = false
        if let _ = album { update(album: album!) }
        albumView.dismiss { [weak self] in
            self?.navBar.badge.isUserInteractionEnabled = true
        }
    }
}

// MARK: - 屏幕旋转
extension MNAssetPickerController {
    override var shouldAutorotate: Bool { false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
}
