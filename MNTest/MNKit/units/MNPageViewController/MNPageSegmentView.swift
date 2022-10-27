//
//  MNPageSegmentView.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/29.
//  分页控制器顶部分段视图

import UIKit

class MNPageSegmentView: UIView {
    /// 数据源
    weak var dataSource: MNPageSegmentDataSource?
    /// 左附属视图
    private weak var leftView: UIView?
    /// 右附属视图
    private weak var rightView: UIView?
    /// 配置信息
    private var options: MNSegmentViewOptions!
    /// 数据源模型
    private var segments: [MNPageSegment] = []
    /// 分割线
    private lazy var separator: UIView = {
        let separator = UIView(frame: CGRect(x: 0.0, y: frame.height - 0.7, width: frame.width, height: 0.7))
        return separator
    }()
    /// 标记选中
    private lazy var shadow: UIImageView = {
        let shadow = UIImageView()
        shadow.contentMode = .scaleToFill
        return shadow
    }()
    
    private(set) lazy var collectionView: UICollectionView = {
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .zero
        layout.scrollDirection = .horizontal
        layout.footerReferenceSize = .zero
        layout.headerReferenceSize = .zero
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(MNPageSegmentCell.self, forCellWithReuseIdentifier: "MNPageSegmentCell")
        return collectionView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(collectionView)
        collectionView.addSubview(shadow)
        addSubview(separator)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(options: MNSegmentViewOptions) {
        self.options = options
        shadow.image = options.shadowImage
        shadow.backgroundColor = options.shadowColor
        separator.backgroundColor = options.separatorColor
        backgroundColor = options.backgroundColor
        collectionView.contentInset = options.contentInset
        collectionView.backgroundColor = options.collectionColor
        var frame = separator.frame
        frame.origin.x = options.separatorInset.left
        frame.size.width = self.frame.width - options.separatorInset.left - options.separatorInset.right
        separator.frame = frame
        var contentInset = options.contentInset
        if let leftView = leftView {
            contentInset.left += leftView.frame.maxX
        }
        if let rightView = rightView {
            contentInset.right += (frame.width - rightView.frame.minX)
        }
        collectionView.contentInset = contentInset
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = options.interitemSpacing
            layout.invalidateLayout()
        }
    }
    
    func reloadSubviews() {
        leftView?.removeFromSuperview()
        rightView?.removeFromSuperview()
        if let leftView = (dataSource?.segmentLeftView ?? nil) {
            leftView.minX = 0.0
            leftView.midY = frame.height/2.0
            insertSubview(leftView, belowSubview: separator)
            self.leftView = leftView
        }
        if let rightView = (dataSource?.segmentRightView ?? nil) {
            rightView.maxX = frame.width
            rightView.midY = frame.height/2.0
            insertSubview(rightView, belowSubview: separator)
            self.rightView = rightView
        }
    }
    
    func reloadData() {
        
    }
    
    func reload(titles: [String]) {
        // 起始
        var x: CGFloat = 0.0
        // 宽度
        let w: CGFloat = options.shadowSize.width
        // 高度
        let h: CGFloat = options.shadowSize.height
        // 标题项高度
        let height: CGFloat = bounds.inset(by: options.contentInset).height
        // 偏移
        let offset: UIOffset = options.shadowOffset
        // 默认底部
        let y: CGFloat = bounds.height - collectionView.contentInset.top - h
        // 标题项追加宽度
        let append: CGFloat = options.itemSize.width
        // 高亮下的放大因数
        let transformScale: CGFloat = max(1.0, options.transformScale)
        // 对齐方式
        let alignment: MNSegmentViewOptions.SegmentShadowAlignment = options.shadowAlignment
        // item间隔
        let interitemSpacing: CGFloat = options.interitemSpacing
        // 标题字体
        let font: UIFont = options.titleFont
        segments.removeAll()
        for title in titles {
            let titleWidth: CGFloat = ceil((title as NSString).size(withAttributes: [.font:font]).width)
            let width: CGFloat = titleWidth + append
            let segment = MNPageSegment()
            segment.title = title
            segment.size = CGSize(width: width, height: height)
            // 标题项位置
            let rect: CGRect = CGRect(x: x, y: 0.0, width: segment.size.width, height: segment.size.height)
            // 标记线位置
            var shadowFrame: CGRect = CGRect(x: 0.0, y: y, width: 0.0, height: h)
            // 高亮时标记线位置
            var highlightFrame: CGRect = shadowFrame
            if options.shadowMask == .fit {
                // 与标题同
                shadowFrame.size.width = titleWidth
                highlightFrame.size.width = ceil(titleWidth*transformScale)
                shadowFrame = aspect(frame: shadowFrame, in: rect, alignment: alignment)
                highlightFrame = aspect(frame: highlightFrame, in: rect, alignment: alignment)
            } else if options.shadowMask == .fill {
                // 与标题栏同宽度
                shadowFrame.origin.x = x
                shadowFrame.size.width = width
                highlightFrame = shadowFrame
            } else {
                // 使用给定宽度
                shadowFrame.size.width = w
                highlightFrame.size.width = w
                shadowFrame = aspect(frame: shadowFrame, in: rect, alignment: alignment)
                highlightFrame = aspect(frame: highlightFrame, in: rect, alignment: alignment)
            }
            shadowFrame.origin.y += offset.vertical
            shadowFrame.origin.x += offset.horizontal
            highlightFrame.origin.y += offset.vertical
            highlightFrame.origin.x += offset.horizontal
            segment.shadowFrame = shadowFrame
            segment.highlightShadowFrame = highlightFrame
            segments.append(segment)
            
            x += (segment.size.width + interitemSpacing)
        }
        // 判断是否充足
        if segments.count > 0, options.contentMode != .normal {
            let total: CGFloat = segments.reduce(0.0) { $0 + $1.size.width }
            let contentWidth: CGFloat = bounds.inset(by: collectionView.contentInset).width
            if contentWidth > total {
                // 不足
                if options.contentMode == .fit {
                    var contentInset: UIEdgeInsets = collectionView.contentInset
                    let inset: CGFloat = max(contentInset.left, contentInset.right)
                    if (total + inset*2.0) > collectionView.frame.width {
                        let short: CGFloat = collectionView.frame.width - total - inset
                        contentInset.left = max(contentInset.left, short)
                        contentInset.right = max(contentInset.right, short)
                    } else if (total + inset*2.0) == collectionView.frame.width {
                        contentInset.left = inset
                        contentInset.right = inset
                    } else {
                        let add: CGFloat = (collectionView.frame.width - total - inset*2.0)/2.0
                        contentInset.left = inset + add
                        contentInset.right = inset + add
                    }
                    collectionView.contentInset = contentInset
                } else if options.contentMode == .fill {
                    let add: CGFloat = (contentWidth - total)/CGFloat(segments.count)
                    for (idx, segment) in segments.enumerated() {
                        segment.size.width += add
                        var shadowFrame = segment.shadowFrame
                        var highlightShadowFrame = segment.highlightShadowFrame
                        if options.shadowMask == .fill {
                            shadowFrame.size.width += add
                            shadowFrame.origin.x += add*CGFloat(idx)
                            highlightShadowFrame.size.width += add
                            highlightShadowFrame.origin.x += add*CGFloat(idx)
                        } else {
                            if options.shadowAlignment == .left {
                                shadowFrame.origin.x += add*CGFloat(idx)
                                highlightShadowFrame.origin.x += add*CGFloat(idx)
                            } else if options.shadowAlignment == .center {
                                shadowFrame.origin.x += (add/2.0 + add*CGFloat(idx))
                                highlightShadowFrame.origin.x += (add/2.0 + add*CGFloat(idx))
                            } else {
                                shadowFrame.origin.x += add*CGFloat(idx + 1)
                                highlightShadowFrame.origin.x += add*CGFloat(idx + 1)
                            }
                        }
                        segment.shadowFrame = shadowFrame
                        segment.highlightShadowFrame = highlightShadowFrame
                    }
                }
            }
        }
    }
    
    private func aspect(frame rect1: CGRect, in rect2: CGRect, alignment: MNSegmentViewOptions.SegmentShadowAlignment) -> CGRect {
        var rect: CGRect = rect1
        switch alignment {
        case .left:
            rect.origin.x = rect2.minX
        case .center:
            rect.origin.x = rect2.minX + (rect2.width - rect1.width)/2.0
        case .right:
            rect.origin.x = rect2.maxX - rect1.width
        }
        return rect
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension MNPageSegmentView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { segments.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: "MNPageSegmentCell", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? MNPageSegmentCell)?.update(segment: segments[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize { segments[indexPath.item].size }
}
