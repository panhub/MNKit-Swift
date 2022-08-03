//
//  MNCollectionViewLabelLayout.swift
//  anhe
//
//  Created by 冯盼 on 2022/6/2.
//  标签约束

import UIKit

class MNCollectionViewLabelLayout: MNCollectionViewLayout {
    
    /// 标签对齐方式
    /// - left: 居左
    /// - center: 居中
    /// - right: 居右
    enum Alignment: Int {
        case left, center, right
    }
    
    /// 对齐方式
    var alignment: Alignment = .left
    
    override func prepare() {
        super.prepare()
        
        // 区数
        guard let numberOfSections = collectionView?.numberOfSections, numberOfSections > 0 else { return }
        
        //var idx: Int = 0
        var top: CGFloat = 0.0
        var attributes: UICollectionViewLayoutAttributes!
        let contentWidth = collectionView!.bounds.inset(by: collectionView!.contentInset).width
        let contentHeight = collectionView!.bounds.inset(by: collectionView!.contentInset).height
        
        guard numberOfSections > 0, contentWidth > 0.0, contentHeight > 0.0 else { return }
        
        // 占位
        for _ in 0..<numberOfSections {
            caches.append([0.0])
        }
        
        // 分区约束
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
            
            let left: CGFloat = sectionInset.left
            let right: CGFloat = sectionInset.right
            let itemCount = collectionView!.numberOfItems(inSection: section)
            var items: [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
            var itemAttributes: [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
            let minimumLineSpacing: CGFloat = minimumLineSpacing(inSection: section)
            let minimumInteritemSpacing: CGFloat = minimumInteritemSpacing(inSection: section)
            
            var x: CGFloat = left
            var y: CGFloat = top
            let max: CGFloat = contentWidth - left - right
            
            for idx in 0..<itemCount {
                let indexPath = IndexPath(item: idx, section: section)
                var itemSize: CGSize = itemSizeOfIndexPath(indexPath)
                itemSize.width = min(itemSize.width, max)
                assert(itemSize.width > 0.0 && itemSize.height > 0.0, "item size unable")
                // 判断是否需要换行
                if x + itemSize.width + right > contentWidth {
                    // 换行
                    layout(attributes: items, surplus: contentWidth - right - x + minimumInteritemSpacing)
                    top = y
                    x = left
                    items.removeAll()
                }
                attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: x, y: top, width: itemSize.width, height: itemSize.height)
                items.append(attributes)
                itemAttributes.append(attributes)
                self.attributes.append(attributes)
                x += (itemSize.width + minimumInteritemSpacing)
                let maxY: CGFloat = attributes.frame.maxY + minimumLineSpacing
                y = y >= maxY ? y : maxY
            }
            
            // 结束时再约束一下位置
            layout(attributes: items, surplus: contentWidth - right - x + minimumInteritemSpacing)
            // 保存区内约束
            sectionAttributes.append(itemAttributes)
            //只要添加, 最后要减去行间隔
            if itemAttributes.count > 0 { top = y - minimumLineSpacing }
            
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
            caches[section][0] = top
        }
        
        // 更新区块
        updateUnions()
    }
    
    /// 依据对齐方式调整约束对象
    /// - Parameters:
    ///   - attributes: 约束对象集合
    ///   - surplus: 剩余宽度
    private func layout(attributes: [UICollectionViewLayoutAttributes], surplus: CGFloat) {
        guard attributes.count > 0 else { return }
        let max: CGFloat = attributes.reduce(attributes[0].frame.height) { $0 > $1.frame.height ? $0 : $1.frame.height }
        // 横向约束
        switch alignment {
        case .center:
            for attribute in attributes {
                var frame = attribute.frame
                frame.origin.x += surplus/2.0
                attribute.frame = frame
            }
        case .right:
            for attribute in attributes {
                var frame = attribute.frame
                frame.origin.x += surplus
                attribute.frame = frame
            }
        default:
            break
        }
        // 纵向约束
        for attribute in attributes {
            var frame = attribute.frame
            frame.origin.y += (max - frame.height)/2.0
            attribute.frame = frame
        }
    }
}
