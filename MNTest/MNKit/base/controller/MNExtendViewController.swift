//
//  MNExtendViewController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/18.
//  附带导航条的控制器基类

import UIKit

@objc class MNExtendViewController: MNBaseViewController {
    // 定制导航条高度
    @objc var navigationBarHeight: CGFloat { MN_NAV_BAR_HEIGHT }
    // 导航条
    fileprivate var _navigationBar: MNNavigationBar!
    // 外界获取导航条
    override var navigationBar: MNNavigationBar! { _navigationBar }
    
    // 初始化时对内容视图约束
    override func initialized() {
        super.initialized()
        if isChildViewController == false {
            edges = edges.union(.top)
        }
    }
    
    // 标题
    override var title: String? {
        get { super.title }
        set {
            super.title = newValue
            _navigationBar?.title = title
        }
    }
    
    override func createView() {
        super.createView()
        if isChildViewController == false {
            if edges.contains(.top) {
                contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: navigationBarHeight + MN_STATUS_BAR_HEIGHT, left: 0.0, bottom: 0.0, right: 0.0))
            }
            let navigationBar = MNNavigationBar(frame: CGRect(x: 0.0, y: 0.0, width: view.width, height: navigationBarHeight + MN_STATUS_BAR_HEIGHT), delegate: self)
            view.addSubview(navigationBar)
            navigationBar.title = title
            _navigationBar = navigationBar
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}

// MARK: - MNNavigationBarDelegate
extension MNExtendViewController: MNNavigationBarDelegate {
    func navigationBarShouldCreateLeftBarItem() -> UIView? { return nil }
    func navigationBarShouldCreateRightBarItem() -> UIView? { return nil }
    func navigationBarShouldDrawBackBarItem() -> Bool { !isRootViewController }
    func navigationBarDidUpdateTitle(_ navigationBar: MNNavigationBar) {}
    func navigationBarDidLayoutSubitems(_ navigationBar: MNNavigationBar) {}
    func navigationBarRightBarItemTouchUpInside(_ rightBarItem: UIView!) {}
    func navigationBarLeftBarItemTouchUpInside(_ leftBarItem: UIView!) {
        pop(animated: UIApplication.shared.applicationState == .active)
    }
}

// MARK: - 获取导航栏
extension UIViewController {
    @objc var navigationBar: MNNavigationBar! {
        var viewController: UIViewController? = self
        while let vc = viewController {
            if vc.isChildViewController {
                viewController = vc.parent
            } else if vc is MNExtendViewController {
                return (vc as! MNExtendViewController)._navigationBar
            } else { break }
        }
        return nil
    }
}
