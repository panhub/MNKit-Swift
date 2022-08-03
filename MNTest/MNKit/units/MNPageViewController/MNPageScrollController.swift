//
//  MNPageScrollController.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/28.
//  分页控制器内的滑动子控制器

import UIKit
import Foundation

struct MNSubpageContainer {
    
    let scrollView: UIScrollView
    let viewController: UIViewController
    
    init?(page: MNSubpageDataSource) {
        guard let vc = page as? UIViewController else { return nil }
        viewController = vc
        scrollView = page.subpageScrollView
    }
}

fileprivate let MNPageScrollAnimationDuration: TimeInterval = 0.3

class MNPageScrollController: MNPageController {
    let kContentSize: String = "ContentSize"
    let kContentOffset: String = "ContentOffset"
    /// 上一次展示的页面索引
    var lastPageIndex: Int = 0
    /// 当前展示的页面索引
    var currentPageIndex: Int = 0
    /// 开始滑动时的偏移
    private var startOffsetX: CGFloat = 0.0
    /// 猜想滑动到的界面索引
    private var guessPageIndex: Int = 0
    /// 页面缓存
    private(set) var pages: [Int:MNSubpageContainer] = [Int:MNSubpageContainer]()
    /// 事件代理
    weak var delegate: MNPageScrollDelegate?
    /// 数据源
    weak var dataSource: MNPageScrollDataSource?
    
    private(set) lazy var scrollView: MNPageScrollView = {
        let scrollView = MNPageScrollView(frame: view.bounds)
        scrollView.delegate = self
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(scrollView)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = object as? UIScrollView, let keyPath = keyPath else { return }
        if keyPath == kContentOffset {
            guard pages.count > 0, scrollView.isAppear, scrollView.subpageIndex == currentPageIndex, scrollView.isContentSizeReached else { return }
            guard let page = pages[scrollView.subpageIndex] else { return }
            delegate?.subpage(page, didScroll: scrollView.contentOffset)
        } else if keyPath == kContentSize {
            let contentSize = scrollView.contentSize
            let minContentSize = scrollView.guessMinContentSize
            if contentSize.height >= minContentSize.height, scrollView.isContentSizeReached == false {
                scrollView.isContentSizeReached = true
                let y: CGFloat = dataSource?.currentPageOffset ?? scrollView.contentOffset.y
                scrollView.setContentOffset(CGPoint(x: 0.0, y: y), animated: false)
            } else if contentSize.height < minContentSize.height, scrollView.isContentSizeReached {
                scrollView.isContentSizeReached = false
            }
        }
    }
}

extension MNPageScrollController {
    
    /// 更新内容尺寸
    func updateContentSize() {
        scrollView.numberOfPages = dataSource?.numberOfPages ?? 0
    }
    
    func displayCurrentPage() {
        scrollView.setOffsetX(pageIndex: currentPageIndex)
    }
    
    func page(index: Int) -> MNSubpageContainer? {
        if let page = pages[index] { return page }
        guard let page = dataSource?.subpage(index: index) else { return nil }
        pages[index] = page
        bindPage(page, index: index)
        addPage(page, index: index)
        return page
    }
    
    func addPage(_ page: MNSubpageContainer, index: Int) {
        let x: CGFloat = scrollView.offsetX(pageIndex: index)
        page.viewController.view.minX = x
        addPageController(page.viewController)
    }
    
    private func addPageController(_ viewController: UIViewController) {
        viewController.willMove(toParent: self)
        scrollView.addSubview(viewController.view)
        addChild(viewController)
        viewController.didMove(toParent: self)
    }
    
    func bindPage(_ page: MNSubpageContainer, index: Int) {
        page.viewController.view.backgroundColor = page.viewController.view.backgroundColor
        let scrollView = page.scrollView
        scrollView.scrollsToTop = false
        scrollView.subpageIndex = index
        let inset = dataSource?.pageTopInset ?? 0.0
        var contentInset = scrollView.contentInset
        contentInset.top += inset
        scrollView.contentInset = contentInset
        scrollView.isInserted = true
        if inset != 0.0 {
            (page.viewController as? MNSubpageDataSource)?.subpage?(scrollView: page.scrollView, appendedTopInset: inset)
        }
        var contentSize = page.scrollView.frame.size
        contentSize.height = contentSize.height - page.scrollView.contentInset.top + (dataSource?.pageMaxOffset ?? 0.0)
        page.scrollView.guessMinContentSize = contentSize
        (page.viewController as? MNSubpageDataSource)?.subpage?(scrollView: page.scrollView, guessMinContentSize: contentSize)
        page.scrollView.addObserver(self, forKeyPath: kContentSize, options: .new, context: nil)
        page.scrollView.addObserver(self, forKeyPath: kContentOffset, options: .new, context: nil)
        page.scrollView.isObserved = true
    }
}

// MARK: - UIScrollViewDelegate 交互过渡
extension MNPageScrollController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView.isDecelerating == false else { return }
        guessPageIndex = currentPageIndex
        if let x = scrollView.value(forKey: "startOffsetX") as? CGFloat {
            startOffsetX = x
        } else {
            startOffsetX = scrollView.contentOffset.x
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging, scrollView.isDecelerating == false, let dataSource = dataSource else { return }
        let numberOfPages: Int = dataSource.numberOfPages
        guard numberOfPages > 0 else { return }
        let width: CGFloat = scrollView.frame.width
        let offsetX: CGFloat = scrollView.contentOffset.x
        // 更新下一界面
        let ratio: CGFloat = offsetX/width
        let lastGuessIndex: Int = guessPageIndex
        if offsetX > startOffsetX {
            guessPageIndex = Int(ceil(ratio))
        } else {
            guessPageIndex = Int(floor(ratio))
        }
        guessPageIndex = min(max(0, currentPageIndex), numberOfPages - 1)
        // 更新生命周期
        if guessPageIndex != currentPageIndex, guessPageIndex != lastGuessIndex {
            // 新出现界面
            //let frome = page(index: currentPageIndex)
            let to = page(index: guessPageIndex)
            // 上次猜想界面
            if lastGuessIndex != currentPageIndex {
                let guess = page(index: lastGuessIndex)
                guess?.viewController.beginAppearanceTransition(false, animated: true)
                delegate?.subpageWillDisappear(guess, animated: true)
                guess?.viewController.endAppearanceTransition()
                delegate?.subpageDidDisappear(guess, animated: true)
            }
            to?.viewController.beginAppearanceTransition(true, animated: true)
            delegate?.subpageWillAppear(to, animated: true)
            to?.viewController.endAppearanceTransition()
            delegate?.subpageDidAppear(to, animated: true)
        }
        // 通知界面滑动
        delegate?.pageController(self, didScroll: ratio, dragging: true)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.pageController(self, didScroll: targetContentOffset.pointee.x/scrollView.frame.width, dragging: false)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView.isDecelerating == false else { return }
        scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lastPageIndex = currentPageIndex
        currentPageIndex = self.scrollView.pageIndex
        if currentPageIndex == lastPageIndex {
            if guessPageIndex != currentPageIndex {
                let guess = page(index: guessPageIndex)
                guess?.viewController.beginAppearanceTransition(false, animated: true)
                delegate?.subpageWillDisappear(guess, animated: true)
                guess?.viewController.endAppearanceTransition()
                delegate?.subpageDidDisappear(guess, animated: true)
            }
        } else {
            let last = page(index: lastPageIndex)
            last?.viewController.beginAppearanceTransition(false, animated: true)
            delegate?.subpageWillDisappear(last, animated: true)
            last?.viewController.endAppearanceTransition()
            delegate?.subpageDidDisappear(last, animated: true)
            if guessPageIndex != currentPageIndex {
                let guess = page(index: guessPageIndex)
                guess?.viewController.beginAppearanceTransition(false, animated: true)
                delegate?.subpageWillDisappear(guess, animated: true)
                guess?.viewController.endAppearanceTransition()
                delegate?.subpageDidDisappear(guess, animated: true)
                let current = page(index: currentPageIndex)
                current?.viewController.beginAppearanceTransition(true, animated: true)
                delegate?.subpageWillAppear(current, animated: true)
                current?.viewController.endAppearanceTransition()
                delegate?.subpageDidAppear(current, animated: true)
                #if DEBUG
                print("⚠️⚠️⚠️交互式过渡有问题⚠️⚠️⚠️")
                #endif
            }
        }
    }
}

// MARK: - UIScrollViewDelegate 非交互过渡
extension MNPageScrollController {
    
    func scrollPage(to index: Int, animated: Bool) {
        guard currentPageIndex != index else { return }
        lastPageIndex = currentPageIndex
        currentPageIndex = index
        let from = page(index: lastPageIndex)
        let to = page(index: currentPageIndex)
        __beginAppearanceTransition()
        if animated {
            guard let fromView = from?.viewController.view, let toView = to?.viewController.view else { return }
            let fromViewStartX: CGFloat = fromView.frame.minX
            var toViewStartX: CGFloat = fromViewStartX
            let offset: CGFloat = lastPageIndex < currentPageIndex ? scrollView.frame.width : -scrollView.frame.width
            toViewStartX += offset
            let toViewEndX: CGFloat = fromViewStartX
            let fromViewEndX: CGFloat = fromViewStartX - offset
            toView.minX = toViewStartX
            UIView.animate(withDuration: MNPageScrollAnimationDuration, delay: 0.0, options: .curveEaseInOut) {
                fromView.minX = fromViewEndX
                toView.minX = toViewEndX
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.displayCurrentPage()
                self.layoutSubview(fromView, index: self.lastPageIndex)
                self.layoutSubview(toView, index: self.currentPageIndex)
                self.__endAppearanceTransition()
            }
        } else {
            displayCurrentPage()
            __endAppearanceTransition()
        }
    }
    
    private func __beginAppearanceTransition() {
        let to = page(index: currentPageIndex)
        if lastPageIndex != currentPageIndex {
            let from = page(index: lastPageIndex)
            from?.viewController.beginAppearanceTransition(false, animated: true)
            delegate?.subpageWillDisappear(from, animated: true)
        }
        to?.viewController.beginAppearanceTransition(true, animated: true)
        delegate?.subpageWillAppear(to, animated: true)
    }
    
    private func __endAppearanceTransition() {
        let to = page(index: currentPageIndex)
        if lastPageIndex != currentPageIndex {
            let from = page(index: lastPageIndex)
            from?.viewController.endAppearanceTransition()
            delegate?.subpageDidDisappear(from, animated: true)
        }
        to?.viewController.endAppearanceTransition()
        delegate?.subpageDidAppear(to, animated: true)
    }
    
    private func layoutSubview(_ subview: UIView, index pageIndex: Int) {
        guard pageIndex >= 0 else { return }
        if let dataSource = dataSource, pageIndex >= dataSource.numberOfPages { return }
        let x: CGFloat = scrollView.offsetX(pageIndex: pageIndex)
        subview.minX = x
    }
}
