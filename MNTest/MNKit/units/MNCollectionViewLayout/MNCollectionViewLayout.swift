//
//  MNCollectionViewLayout.swift
//  anhe
//
//  Created by 冯盼 on 2022/6/2.
//  数据流约束对象

import UIKit

/**标记视图*/
struct MNCollectionElement {
    // 类型
    struct Kind {
        static let header: String = "com.mn.collection.element.kind.section.header"
        static let footer: String = "com.mn.collection.element.kind.section.footer"
    }
    // 标识符
    struct Identifier {
        static let cell: String = "com.mn.collection.element.cell.reuseIdentifier"
        static let header: String = "com.mn.collection.element.section.header.reuseIdentifier"
        static let footer: String = "com.mn.collection.element.section.footer.reuseIdentifier"
    }
}

@objc protocol MNCollectionViewLayoutDelegate: NSObjectProtocol {
    /**获取区间隔*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, insetForSectionAt index: Int) -> UIEdgeInsets
    /**获取区头间隔*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, insetForHeaderInSection section: Int) -> UIEdgeInsets
    /**获取区尾间隔*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, insetForFooterInSection section: Int) -> UIEdgeInsets
    /**获取相邻项间隔*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    /**获取行间隔*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    /**获取区头尺寸*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    /**获取区尾尺寸*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize
    /**获取每一项尺寸*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    /**获取区列数/行数*/
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: MNCollectionViewLayout, numberOfColumnsInSection section: Int) -> Int
}

public class MNCollectionViewLayout: UICollectionViewLayout {
    /**尺寸*/
    public var itemSize: CGSize = .zero {
        didSet { invalidateLayout() }
    }
    /**纵向相邻间隔*/
    public var minimumLineSpacing: CGFloat = 10.0 {
        didSet { invalidateLayout() }
    }
    /**横向相邻间隔*/
    public var minimumInteritemSpacing: CGFloat = 10.0 {
        didSet { invalidateLayout() }
    }
    /**区头大小(竖向取高度, 纵向取宽度)*/
    public var headerReferenceSize: CGSize = .zero {
        didSet { invalidateLayout() }
    }
    /**区尾大小(竖向取高度, 纵向取宽度)*/
    public var footerReferenceSize: CGSize = .zero {
        didSet { invalidateLayout() }
    }
    /**区头间隔*/
    public var headerInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }
    /**区尾间隔*/
    public var footerInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }
    /**区间隔*/
    public var sectionInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }
    /**纵向列数, 横向行数*/
    public var numberOfColumns: Int = 3 {
        didSet { invalidateLayout() }
    }
    /**指定内容尺寸*/
    public var contentSize: CGSize = .zero {
        didSet { invalidateLayout() }
    }
    /**单位区块包含的数量*/
    private static let AttributesUnion: Int = 20
    /**区内每一列/行的高/宽缓存*/
    var caches: [[CGFloat]] = [[CGFloat]]()
    /**所有布局对象(包括区头区尾)缓存*/
    var attributes: [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
    /**区头布局对象缓存*/
    var headerAttributes: [Int: UICollectionViewLayoutAttributes] = [Int: UICollectionViewLayoutAttributes]()
    /**区尾布局对象缓存*/
    var footerAttributes: [Int: UICollectionViewLayoutAttributes] = [Int: UICollectionViewLayoutAttributes]()
    /**区布局对象缓存*/
    var sectionAttributes: [[UICollectionViewLayoutAttributes]] = [[UICollectionViewLayoutAttributes]]()
    /**周期内布局对象的范围, 便于后期计算返回*/
    private var unions: [CGRect] = [CGRect]()
    /**数据源代理*/
    weak var delegate: MNCollectionViewLayoutDelegate?
    
    /**重写*/
    public override func prepare() {
        super.prepare()
        unions.removeAll()
        caches.removeAll()
        attributes.removeAll()
        footerAttributes.removeAll()
        headerAttributes.removeAll()
        sectionAttributes.removeAll()
        if delegate == nil {
            delegate = collectionView?.dataSource as? MNCollectionViewLayoutDelegate
        }
    }
    
    public override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        var size = collectionView.bounds.inset(by: collectionView.contentInset).size
        if attributes.count > 0 {
            size.height = max(contentSize.height, caches.last!.first!)
        } else {
            size.height = contentSize.height
        }
        return size
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < sectionAttributes.count else { return nil }
        guard indexPath.item < sectionAttributes[indexPath.section].count else { return nil }
        return sectionAttributes[indexPath.section][indexPath.item]
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == MNCollectionElement.Kind.header {
            return headerAttributes[indexPath.section]
        } else if elementKind == MNCollectionElement.Kind.footer {
            return footerAttributes[indexPath.section]
        }
        return nil
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var begin: Int = 0
        var end: Int = 0
        var cells = [IndexPath: UICollectionViewLayoutAttributes]()
        var headers = [IndexPath: UICollectionViewLayoutAttributes]()
        var footers = [IndexPath: UICollectionViewLayoutAttributes]()
        var decorations = [IndexPath: UICollectionViewLayoutAttributes]()
        
        for i in 0..<unions.count {
            if rect.intersects(unions[i]) {
                begin = i*MNCollectionViewLayout.AttributesUnion
                break
            }
        }
        
        for i in (0..<unions.count).reversed() {
            if rect.intersects(unions[i]) {
                end = min((i + 1)*MNCollectionViewLayout.AttributesUnion, attributes.count)
                break
            }
        }
        
        for i in begin..<end {
            let attributes = attributes[i]
            if rect.intersects(attributes.frame) {
                switch attributes.representedElementCategory {
                case .cell:
                    cells[attributes.indexPath] = attributes
                case .decorationView:
                    decorations[attributes.indexPath] = attributes
                case .supplementaryView:
                    if attributes.representedElementKind == MNCollectionElement.Kind.header {
                        headers[attributes.indexPath] = attributes
                    } else if attributes.representedElementKind == MNCollectionElement.Kind.footer {
                        footers[attributes.indexPath] = attributes
                    }
                @unknown default:
                    #if DEBUG
                    print("'layoutAttributesForElements(in:)' 出现未确定选项")
                    #endif
                }
            }
        }
        
        var result = [UICollectionViewLayoutAttributes]()
        result.append(contentsOf: cells.values)
        result.append(contentsOf: headers.values)
        result.append(contentsOf: footers.values)
        result.append(contentsOf: decorations.values)
        
        return result.count > 0 ? result : nil
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
        return newBounds.size != collectionView.bounds.size
    }
}

// MARK: - 获取约束信息
extension MNCollectionViewLayout {
    /**列数/行数*/
    func numberOfColumns(inSection section: Int) -> Int {
        guard let columns = delegate?.collectionView?(collectionView!, layout: self, numberOfColumnsInSection: section) else { return max(numberOfColumns, 1) }
        return max(columns, 1)
    }
    /**行间隔*/
    func minimumLineSpacing(inSection section: Int) -> CGFloat {
        guard let height = delegate?.collectionView?(collectionView!, layout: self, minimumLineSpacingForSectionAt: section) else { return minimumLineSpacing }
        return height
    }
    /**相邻间隔*/
    func minimumInteritemSpacing(inSection section: Int) -> CGFloat {
        guard let height = delegate?.collectionView?(collectionView!, layout: self, minimumInteritemSpacingForSectionAt: section) else { return minimumInteritemSpacing }
        return height
    }
    /**区间隔*/
    func sectionInset(atIndex section: Int) -> UIEdgeInsets {
        guard let inset = delegate?.collectionView?(collectionView!, layout: self, insetForSectionAt: section) else { return sectionInset }
        return inset
    }
    /**每一项尺寸*/
    func itemSizeOfIndexPath(_ indexPath: IndexPath) -> CGSize {
        guard let size = delegate?.collectionView?(collectionView!, layout: self, sizeForItemAt: indexPath) else { return itemSize }
        return size
    }
    /**区头尺寸*/
    func referenceSizeForHeader(inSection section: Int) -> CGSize {
        guard let size = delegate?.collectionView?(collectionView!, layout: self, referenceSizeForHeaderInSection: section) else { return headerReferenceSize }
        return size
    }
    /**区尾尺寸*/
    func referenceSizeForFooter(inSection section: Int) -> CGSize {
        guard let size = delegate?.collectionView?(collectionView!, layout: self, referenceSizeForFooterInSection: section) else { return footerReferenceSize }
        return size
    }
    /**区头间隔*/
    func headerInset(inSection section: Int) -> UIEdgeInsets {
        guard let inset = delegate?.collectionView?(collectionView!, layout: self, insetForHeaderInSection: section) else { return headerInset }
        return inset
    }
    /**区尾间隔*/
    func footerInset(inSection section: Int) -> UIEdgeInsets {
        guard let inset = delegate?.collectionView?(collectionView!, layout: self, insetForFooterInSection: section) else { return footerInset }
        return inset
    }
    /**寻找最短一列/行*/
    func shortestColumnIndex(inSection section: Int) -> Int {
        let items = caches[section]
        var index: Int = 0
        var height: CGFloat = CGFloat.greatestFiniteMagnitude
        for idx in 0..<items.count {
            let h = items[idx]
            if h < height {
                height = h
                index = idx
            }
        }
        return index
    }
    /**寻找最长一列/行*/
    func longestColumnIndex(inSection section: Int) -> Int {
        let items = caches[section]
        var index: Int = 0
        var height: CGFloat = 0.0
        for idx in 0..<items.count {
            let h = items[idx]
            if h > height {
                height = h
                index = idx
            }
        }
        return index
    }
    
    /**更新区块*/
    func updateUnions() -> Void {
        // 保存区域便于查找
        var idx: Int = 0
        while idx < attributes.count {
            var rect = attributes[idx].frame
            let endIndex = min(idx + MNCollectionViewLayout.AttributesUnion, attributes.count)
            for i in (idx + 1)..<endIndex {
                rect = rect.union(attributes[i].frame)
            }
            idx = endIndex
            unions.append(rect)
        }
    }
}
