//
//  MNPageControl.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/27.
//  页码指示器

import UIKit

@objc protocol MNPageControlDataSource: NSObjectProtocol {
    /// 询问页码总数
    /// - Parameter pageControl: 指示器
    /// - Returns: 页码总数
    @objc optional func numberOfPages(in pageControl: MNPageControl) -> Int
    /// 定制指示器
    /// - Parameters:
    ///   - pageControl: 指示器
    ///   - index: 页码索引
    /// - Returns: 指示器视图
    @objc optional func pageControl(_ pageControl: MNPageControl, viewForPageIndicator index: Int) -> UIView
}

@objc protocol MNPageControlDelegate: NSObjectProtocol {
    /// 交互式修改页码指示器
    /// - Parameters:
    ///   - pageControl: 指示器
    ///   - index: 页码索引
    @objc optional func pageControl(_ pageControl: MNPageControl, didSelectPageAt index: Int) -> Void
    /// 告知需要更新指示器视图
    /// - Parameters:
    ///   - pageControl: 指示器
    ///   - indicator: 指示器视图
    ///   - index: 页码索引
    @objc optional func pageControl(_ pageControl: MNPageControl, shouldUpdate indicator: UIView, forPageAt index: Int) -> Void
    /// 告知已加载指示器视图
    /// - Parameters:
    ///   - pageControl: 指示器
    ///   - indicator: 指示器视图
    ///   - index: 页码索引
    @objc optional func pageControl(_ pageControl: MNPageControl, didEndDisplaying indicator: UIView, forPageAt index: Int) -> Void
}

/// 页码指示器
class MNPageControl: UIView {
    
    /// 布局方向
    enum Axis: Int {
        case horizontal, vertical
    }
    
    /// 布局方向
    var axis: Axis = .horizontal
    /// 页码间隔
    var spacing: CGFloat = 10.0
    /// 指示器大小
    var pageIndicatorSize: CGSize = CGSize(width: 8.0, height: 8.0)
    /// 边距
    var contentInset: UIEdgeInsets = UIEdgeInsets(top: 13.0, left: 15.0, bottom: 13.0, right: 15.0)
    /// 触摸区域
    var touchInset: UIEdgeInsets = .zero
    /// 指示器触摸区域
    var indicatorTouchInset: UIEdgeInsets = .zero
    /// 页码数量 代理优先
    var numberOfPages: Int = 0
    /// 当前选中的页码索引
    var currentPageIndex: Int = 0 {
        willSet { updateIndicator(index: currentPageIndex, selected: false) }
        didSet { updateIndicator(index: currentPageIndex, selected: true) }
    }
    /// 指示器颜色
    var pageIndicatorTintColor: UIColor? = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1.0)
    /// 当前指示器颜色
    var currentPageIndicatorTintColor: UIColor? = UIColor(red: 125.0/255.0, green: 125.0/255.0, blue: 125.0/255.0, alpha: 1.0)
    /// 事件代理
    weak var delegate: MNPageControlDelegate?
    /// 数据源代理
    weak var dataSource: MNPageControlDataSource?
    /// 缓存池
    private var cache: [Int:UIView] = [Int:UIView]()
    /// 放置指示器
    private let contentView: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        backgroundColor = UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        
        contentView.frame = bounds
        contentView.isUserInteractionEnabled = false
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        if let _ = superview {
            reloadData()
        }
        super.didMoveToSuperview()
    }
    
    /// 刷新指示器
    func reloadData() {
        
        // 删除指示器
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }
        
        // 指示器数量
        let count: Int = dataSource?.numberOfPages?(in: self) ?? numberOfPages
        
        // 更新位置
        var rect: CGRect = frame
        if axis == .horizontal {
            rect.size.height = contentInset.top + contentInset.bottom + pageIndicatorSize.height*CGFloat(count > 0 ? 1 : 0)
            rect.size.width = contentInset.left + contentInset.right + pageIndicatorSize.width*CGFloat(count) + spacing*CGFloat(max(0, count - 1))
        } else {
            rect.size.width = contentInset.left + contentInset.right + pageIndicatorSize.width*CGFloat(count > 0 ? 1 : 0)
            rect.size.height = contentInset.top + contentInset.bottom + pageIndicatorSize.height*CGFloat(count) + spacing*CGFloat(max(0, count - 1))
        }
        frame = rect
        
        // 添加指示器
        guard count > 0 else { return }
        for index in 0..<count {
            
            var x: CGFloat = contentInset.left
            var y: CGFloat = contentInset.top
            if axis == .horizontal {
                x += ((pageIndicatorSize.width + spacing)*CGFloat(index))
            } else {
                y += ((pageIndicatorSize.height + spacing)*CGFloat(index))
            }
            let rect = CGRect(x: x, y: y, width: pageIndicatorSize.width, height: pageIndicatorSize.height)
            
            let indicator = indicator(index: index)
            indicator.frame = rect
            indicator.backgroundColor = index == currentPageIndex ? currentPageIndicatorTintColor : pageIndicatorTintColor
            contentView.addSubview(indicator)
            delegate?.pageControl?(self, didEndDisplaying: indicator, forPageAt: index)
            indicator.clipsToBounds = true
            indicator.layer.cornerRadius = min(pageIndicatorSize.width, pageIndicatorSize.height)/2.0
        }
    }
    
    private func indicator(index: Int) -> UIView {
        if let view = cache[index] { return view }
        let indicator: UIView = dataSource?.pageControl?(self, viewForPageIndicator: index) ?? UIView()
        cache[index] = indicator
        return indicator
    }
    
    private func updateIndicator(index: Int, selected: Bool) -> Void {
        guard index < contentView.subviews.count else { return }
        let indicator: UIView = contentView.subviews[index]
        if let delegate = delegate, delegate.responds(to: #selector(delegate.pageControl(_:shouldUpdate:forPageAt:))) {
            delegate.pageControl?(self, didEndDisplaying: indicator, forPageAt: index)
        } else {
            indicator.backgroundColor = selected ? currentPageIndicatorTintColor : pageIndicatorTintColor
        }
    }
    
    private func update(touches: Set<UITouch>, with event: UIEvent?) {
        guard let event = event, event.type == .touches else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        for (index, indicator) in contentView.subviews.enumerated() {
            guard indicator.frame.inset(by: indicatorTouchInset).contains(location) else { continue }
            currentPageIndex = index
            delegate?.pageControl?(self, didSelectPageAt: index)
            break
        }
    }
}

// MARK: - Touch
extension MNPageControl {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        update(touches: touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        update(touches: touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        update(touches: touches, with: event)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let event = event, event.type == .touches {
            return bounds.inset(by: touchInset).contains(point)
        }
        return super.point(inside: point, with: event)
    }
}
