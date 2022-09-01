//
//  MNCollectionViewFlowLayout.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/5.
//  数据流约束对象

import UIKit

public class MNCollectionViewFlowLayout: MNCollectionViewLayout {
    
    /**滑动方向*/
    public enum ScrollDirection : Int {
        case vertical, horizontal
    }
    
    /**滑动方向*/
    var scrollDirection: ScrollDirection = .vertical {
        didSet { invalidateLayout() }
    }
    
    public override func prepare() {
        super.prepare()
        switch scrollDirection {
        case .vertical:
            vertical()
        case .horizontal:
            horizontal()
        }
    }
    
    public override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        var size = collectionView.bounds.inset(by: collectionView.contentInset).size
        if attributes.count > 0 {
            if scrollDirection == .vertical {
                size.height = max(contentSize.height, caches.last!.first!)
            } else {
                size.width = max(contentSize.width, caches.last!.first!)
            }
        } else {
            if scrollDirection == .vertical {
                size.height = contentSize.height;
            } else {
                size.width = contentSize.width;
            }
        }
        return size
    }
}

// 纵向约束
private extension MNCollectionViewFlowLayout {
    func vertical() -> Void {
        // 区数
        guard let numberOfSections = collectionView?.numberOfSections, numberOfSections > 0 else { return }
        
        var top: CGFloat = 0.0
        var attributes: UICollectionViewLayoutAttributes!
        let contentWidth = collectionView!.bounds.inset(by: collectionView!.contentInset).width
        let contentHeight = collectionView!.bounds.inset(by: collectionView!.contentInset).height
        
        guard numberOfSections > 0, contentWidth > 0.0, contentHeight > 0.0 else { return }
        
        // 占位
        for section in 0..<numberOfSections {
            let columnCount = numberOfColumns(inSection: section)
            let sectionColumnHeights: [CGFloat] = [CGFloat](repeating: 0.0, count: columnCount)
            caches.append(sectionColumnHeights)
        }
        
        // 区
        for section in 0..<numberOfSections {
            // 区边缘约束
            let sectionInset = sectionInset(atIndex: section)
            // 区顶部间隔
            top += sectionInset.top
            // 区头间隔
            let headerInset = headerInset(inSection: section)
            let headerHeight = referenceSizeForHeader(inSection: section).height
            top += headerInset.top
            if headerHeight > 0.0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MNCollectionElement.Kind.header, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: sectionInset.left + headerInset.left, y: top, width: contentWidth - sectionInset.left - sectionInset.right - headerInset.left - headerInset.right, height: headerHeight)
                headerAttributes[section] = attributes
                self.attributes.append(attributes)
                top = attributes.frame.maxY
            }
            top += headerInset.bottom
            
            // 区内数量
            let columnCount = numberOfColumns(inSection: section)
            
            // 标记此时高度
            for idx in 0..<columnCount {
                caches[section][idx] = top
            }
            
            let width = contentWidth - sectionInset.left - sectionInset.right
            var minimumInteritemSpacing = minimumInteritemSpacing(inSection: section)
            let itemWidth = floor((width - CGFloat(columnCount - 1)*minimumInteritemSpacing)/CGFloat(columnCount))
            
            assert(itemWidth >= 0.0, "item width < 0.0 unable")
            
            let spacing = width - CGFloat(columnCount)*itemWidth - CGFloat(columnCount - 1)*minimumInteritemSpacing
            if spacing > 0.0, columnCount > 1 {
                minimumInteritemSpacing += (spacing/CGFloat(columnCount - 1))
            }
            
            let minimumLineSpacing = minimumLineSpacing(inSection: section)
            let itemCount = collectionView!.numberOfItems(inSection: section)
            var itemAttributes:[UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
            
            for idx in 0..<itemCount {
                // 当前
                let indexPath = IndexPath(item: idx, section: section)
                // 需要追加的列
                let appendIndex = shortestColumnIndex(inSection: section)
                let x = sectionInset.left + (itemWidth + minimumInteritemSpacing)*CGFloat(appendIndex);
                // 这里不加行间隔 避免第一列出错
                let y = caches[section][appendIndex]
                let itemSize = itemSizeOfIndexPath(indexPath)
                var itemHeight: CGFloat = 0.0
                if abs(itemSize.width - itemWidth) < 0.1 {
                    itemHeight = floor(itemSize.height)
                } else if itemSize.width > 0.0 {
                    itemHeight = floor((itemSize.height/itemSize.width)*itemWidth)
                }
                attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
                itemAttributes.append(attributes)
                self.attributes.append(attributes)
                // 保存时添加间隔
                caches[section][appendIndex] = attributes.frame.maxY + minimumLineSpacing
            }
            
            sectionAttributes.append(itemAttributes)
            
            // 更新顶部标记
            let longestColumnIndex = longestColumnIndex(inSection: section)
            top = caches[section][longestColumnIndex]
            // 这里减去是因为保存时加了行间隔
            if itemAttributes.count > 0  { top -= minimumLineSpacing }
            
            // 区尾间隔
            let footerInset = footerInset(inSection: section)
            let footerHeight = referenceSizeForFooter(inSection: section).height
            top += footerInset.top
            if footerHeight > 0.0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MNCollectionElement.Kind.footer, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: sectionInset.left + footerInset.left, y: top, width: contentWidth - sectionInset.left - sectionInset.right - footerInset.left - footerInset.right, height: footerHeight)
                footerAttributes[section] = attributes
                self.attributes.append(attributes)
                top = attributes.frame.maxY
            }
            top += footerInset.bottom
            
            // 区底部间隔
            top += sectionInset.bottom
            
            // 标记此时高度
            for idx in 0..<columnCount {
                caches[section][idx] = top
            }
        }
        
        // 更新区块
        updateUnions()
    }
}

// 横向约束
private extension MNCollectionViewFlowLayout {
    private func horizontal() -> Void {
        // 区数
        guard let numberOfSections = collectionView?.numberOfSections, numberOfSections > 0 else { return }
        
        var right: CGFloat = 0.0
        var attributes: UICollectionViewLayoutAttributes!
        let contentWidth = collectionView!.bounds.inset(by: collectionView!.contentInset).width
        let contentHeight = collectionView!.bounds.inset(by: collectionView!.contentInset).height
        
        guard numberOfSections > 0, contentWidth > 0.0, contentHeight > 0.0 else { return }
        
        // 占位
        for section in 0..<numberOfSections {
            let columnCount = numberOfColumns(inSection: section)
            let sectionColumnWidths: [CGFloat] = [CGFloat](repeating: 0.0, count: columnCount)
            caches.append(sectionColumnWidths)
        }
        
        // 区
        for section in 0..<numberOfSections {
            
            let sectionInset = sectionInset(atIndex: section)
            
            // 区顶部间隔
            right += sectionInset.left
            
            // 区头间隔
            let headerInset = headerInset(inSection: section)
            let headerWidth = referenceSizeForHeader(inSection: section).width
            right += headerInset.left
            if headerWidth > 0.0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MNCollectionElement.Kind.header, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: right, y: sectionInset.top + headerInset.top, width: headerWidth, height: contentHeight - sectionInset.top - headerInset.top - sectionInset.bottom - headerInset.bottom)
                headerAttributes[section] = attributes
                self.attributes.append(attributes)
                right = attributes.frame.maxX
            }
            right += headerInset.right
            
            // 区行数
            let columnCount = numberOfColumns(inSection: section)
            
            // 标记此时宽度
            for idx in 0..<columnCount {
                caches[section][idx] = right
            }
            
            let height = contentHeight - sectionInset.top - sectionInset.bottom
            let minimumInteritemSpacing = minimumInteritemSpacing(inSection: section)
            let itemHeight: CGFloat = floor((height - CGFloat(columnCount - 1)*minimumInteritemSpacing)/CGFloat(columnCount))
            
            assert(itemHeight >= 0.0, "item height <= 0.0 unable")
            
            let minimumLineSpacing = minimumLineSpacing(inSection: section)
            let itemCount = collectionView!.numberOfItems(inSection: section)
            var itemAttributes:[UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
            
            for idx in 0..<itemCount {
                // 当前
                let indexPath = IndexPath(item: idx, section: section)
                // 需要追加的行
                let appendIndex = shortestColumnIndex(inSection: section)
                let y = sectionInset.top + (itemHeight + minimumLineSpacing)*CGFloat(appendIndex);
                // 这里不添加间隔 避免第一列出错
                let x = caches[section][appendIndex]
                let itemSize = itemSizeOfIndexPath(indexPath)
                var itemWidth: CGFloat = 0.0
                if itemSize.height > 0.0 {
                    itemWidth = floor((itemSize.width/itemSize.height)*itemHeight)
                }
                attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
                itemAttributes.append(attributes)
                self.attributes.append(attributes)
                // 保存时添加间隔
                caches[section][appendIndex] = attributes.frame.maxX + minimumInteritemSpacing
            }
            
            sectionAttributes.append(itemAttributes)
            
            // 更新右标记
            let longestColumnIndex = longestColumnIndex(inSection: section)
            right = caches[section][longestColumnIndex]
            if itemAttributes.count > 0 { right -= minimumInteritemSpacing }
            
            // 区尾间隔
            let footerInset = footerInset(inSection: section)
            let footerWidth = referenceSizeForFooter(inSection: section).width
            right += footerInset.right
            if footerWidth > 0.0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: MNCollectionElement.Kind.footer, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: right, y: sectionInset.top + footerInset.top, width: footerWidth, height: contentHeight - sectionInset.left - sectionInset.right - headerInset.left - headerInset.right)
                footerAttributes[section] = attributes
                self.attributes.append(attributes)
                right = attributes.frame.maxX
            }
            right += footerInset.right
            
            // 区底部间隔
            right += sectionInset.right
            
            // 标记此时高度
            for idx in 0..<columnCount {
                caches[section][idx] = right
            }
        }
        // 更新区块
        updateUnions()
    }
}
