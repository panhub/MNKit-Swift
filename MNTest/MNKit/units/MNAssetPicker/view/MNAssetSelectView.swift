//
//  MNAssetSelectView.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/2/4.
//  媒体资源选择视图

import UIKit

protocol MNAssetSelectViewDelegate: NSObjectProtocol {
    // 选择回调
    func selectView(_ selectView: MNAssetSelectView, didSelectItemAtIndex selectIndex: Int) -> Void
}

class MNAssetSelectView: UIView {
    // 媒体资源
    private let assets: [MNAsset]
    // 配置信息
    private let config: MNAssetPickerOptions
    // 选择索引
    private var selectIndex: Int = 0
    // 事件代理
    weak var delegate: MNAssetSelectViewDelegate?
    // 集合视图
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 13.0
        layout.minimumInteritemSpacing = 0.0
        layout.headerReferenceSize = .zero
        layout.footerReferenceSize = .zero
        layout.itemSize = CGSize(width: frame.height - 26.0, height: frame.height - 26.0)
        layout.sectionInset = UIEdgeInsets(top: 13.0, left: 13.0, bottom: 13.0, right: 13.0)
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.scrollsToTop = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceHorizontal = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(MNAssetSelectCell.self, forCellWithReuseIdentifier: "com.mn.asset.select.cell")
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never;
        }
        return collectionView
    }()
    
    init(frame: CGRect, assets: [MNAsset], config: MNAssetPickerOptions) {
        self.assets = assets
        self.config = config
        super.init(frame: frame)
        
        backgroundColor = UIColor(red: 32.0/255.0, green: 32.0/255.0, blue: 35.0/255.0, alpha: 0.45)
        
        addSubview(collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(selectIndex index: Int) {
        let lastSelectIndex = self.selectIndex
        selectIndex = index
        var indexPaths: [IndexPath] = [IndexPath(item: lastSelectIndex, section: 0)]
        if index != lastSelectIndex { indexPaths.append(IndexPath(item: index, section: 0)) }
        UIView.performWithoutAnimation { [weak self] in
            self?.collectionView.reloadData()
        }
        //updateSubview()
    }
    
    func updateSubview() {
        guard let superview = superview, selectIndex < assets.count else { return }
        let asset: MNAsset = assets[selectIndex]
        if asset.type == .video {
            if maxY >= superview.bounds.height {
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
                    guard let self = self else { return }
                    self.height = self.collectionView.height
                    self.maxY = superview.bounds.height - MNAssetBrowserCell.ToolBarHeight
                }, completion: nil)
            }
        } else if maxY < superview.bounds.height {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
                guard let self = self else { return }
                self.height = self.collectionView.frame.maxY + MNAssetBrowserCell.ToolBarHeight
                self.maxY = superview.bounds.height
            }, completion: nil)
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension MNAssetSelectView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { assets.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "com.mn.asset.select.cell", for: indexPath)
        (cell as? MNAssetSelectCell)?.borderView.layer.borderColor = config.color.cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay c: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = c as? MNAssetSelectCell else { return }
        cell.update(asset: assets[indexPath.item])
        cell.update(selected: indexPath.item == selectIndex)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item != selectIndex else { return }
        delegate?.selectView(self, didSelectItemAtIndex: indexPath.item)
    }
}
