//
//  MNBaseViewController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/7/18.
//  控制器基类(提供基础功能)

import UIKit
import Foundation
import CoreGraphics

class MNBaseViewController: UIViewController {
    // 位置
    private var frame: CGRect = UIScreen.main.bounds
    // 是否显示
    @objc private(set) var isAppear: Bool = false
    // 是否第一次显示
    @objc private(set) var isFirstAppear: Bool = true
    // 是否需要刷新数据
    private var isNeedReloadData: Bool = false
    // 内容视图
    @objc var contentView: UIView!
    // 内容约束
    var edges: UIViewController.Edge = []
    // 状态栏相关
    var isStatusBarHidden: Bool = false
    var statusBarStyle: UIStatusBarStyle = .default
    var statusBarAnimation: UIStatusBarAnimation = .fade
    // 请求体
    @objc var httpRequest: HTTPPageRequest?
    // 标记是否主控制器
    override var isChildViewController: Bool { false }
    // 空数据视图
    @objc var emptySuperview: UIView { contentView }
    @objc var emptyViewFrame: CGRect { emptySuperview.bounds }
    @objc lazy var emptyView: MNEmptyView = {
        let emptyView = MNEmptyView(frame: emptyViewFrame)
        emptyView.isHidden = true
        emptyView.delegate = self
        emptyView.text = "暂无数据"
        return emptyView
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.initialized()
    }
    
    @objc public init() {
        super.init(nibName: nil, bundle: nil)
        self.initialized()
    }
    
    @objc public init(title: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.initialized()
    }
    
    @objc public init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
        self.frame = frame
        self.initialized()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 初始化自身属性
    @objc func initialized() -> Void {
        layoutExtendAdjustEdges()
        if isRootViewController {
            edges = .bottom
        }
    }
    
    override func loadView() {
        let view = UIView(frame: self.frame)
        view.backgroundColor = .white
        view.isUserInteractionEnabled = true
        self.view = view
        createView()
    }
    
    @objc func createView() -> Void {
        let contentView = UIView(frame: view.bounds.inset(by: UIEdgeInsets(top: 0.0, left: 0.0, bottom: edges.contains(.bottom) ? MN_TAB_BAR_HEIGHT : 0.0, right: 0.0)))
        contentView.backgroundColor = .white
        contentView.isUserInteractionEnabled = true
        view.addSubview(contentView)
        self.contentView = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isChildViewController == false {
            setNeedsUpdateStatusBar(animated ? .fade : .none)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isAppear = true
        reloadDataIfNeeded()
        if isChildViewController == false {
            setNeedsUpdateStatusBar(animated ? .fade : .none)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isFirstAppear = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isAppear = false
    }
    
    /**处理请求*/
    @objc func loadData() {
        guard let request = httpRequest, request.isLoading == false else { return }
        request.load { [weak self, weak request] in
            guard let self = self, let request = request else { return }
            self.prepare(request: request)
        } completion: { [weak self, weak request] result in
            guard let self = self, let request = request else { return }
            let _ = self.finish(request: request, result: result)
            self.finish(request: request)
        }
    }
    
    /**依据显示状态刷新数据*/
    @objc func setNeedsReloadData() {
        isNeedReloadData = true
    }
    
    @objc func reloadDataIfNeeded() {
        guard isNeedReloadData else { return }
        isNeedReloadData = false
        reloadData()
    }
    
    /**刷新数据*/
    @objc func reloadData() {
        httpRequest?.cancel()
        httpRequest?.prepareReload()
        loadData()
    }
    
    // 即将开始请求
    @objc func prepare(request: HTTPPageRequest) {
        if contentView.existToast == false {
            contentView.showActivityToast("请稍后")
        }
    }
    // 请求结束
    @objc func finish(request: HTTPPageRequest) {
        contentView.closeToast()
    }
    // 请求结束
    @objc func finish(request: HTTPPageRequest, result: HTTPResult) -> Bool {
        let isEmpty = request.isEmpty
        let isSuccess = result.isSuccess
        showEmpty(isEmpty, image: nil, text: nil, title: nil, event: (request.page == 1 ? .reload : .load))
        if isEmpty == false, isSuccess == false {
            // 数据不为空, 但请求失败了, 弹窗提示错误信息
            contentView.showMsgToast(result.msg)
        }
        return (isSuccess == true && isEmpty == false)
    }
    
    // 显示空数据视图
    @objc func showEmpty(_ needs: Bool, image: UIImage? = nil, text: String? = nil, title: String? = nil, event: MNEmptyView.Event = .reload) {
        if needs {
            layoutEmptyView()
            emptyView.event = event
            emptyView.isHidden = false
            emptyView.title = title ?? emptyView.title
            emptyView.text = text ?? emptyView.text
            emptyView.image = image ?? emptyView.image
            emptyView.setNeedsLayout()
            emptyViewDidAppear(emptyView)
        } else {
            emptyView.isHidden = true
        }
    }
    
    /// 告知展示空数据视图
    /// - Parameter emptyView: 空数据视图
    @objc func emptyViewDidAppear(_ emptyView: MNEmptyView) {}
    
    /// 告知添加空数据视图
    /// - Parameters:
    ///   - emptyView: 空数据视图
    ///   - superview: 父视图
    @objc func didMoveEmptyView(toSuperview superview: UIView) {}
    
    /// 约束空数据视图
    @objc func layoutEmptyView() {
        if emptyView.frame != emptyViewFrame {
            emptyView.frame = emptyViewFrame
        }
        if emptyView.superview == nil || emptyView.superview! != emptySuperview {
            emptyView.removeFromSuperview()
            emptySuperview.addSubview(emptyView)
            didMoveEmptyView(toSuperview: emptyView.superview!)
        } else {
            emptyView.superview!.bringSubviewToFront(emptyView)
        }
    }
    
    /// 触摸背景 收起键盘
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - 空数据相关操作
extension MNBaseViewController: MNEmptyViewDelegate {
    // 空数据视图代理
    func emptyViewButtonTouchUpInside(_ emptyView: MNEmptyView) {
        guard emptyView.event != .custom else { return }
        emptyView.isHidden = true
        if emptyView.event == .load {
            // 加载数据
            loadData()
        } else {
            // 重载数据
            reloadData()
        }
    }
}

// MARK: - 状态栏更换
extension MNBaseViewController {
    
    func setStatusBarHidden(_ isHidden: Bool, animation: UIStatusBarAnimation = .fade) {
        isStatusBarHidden = isHidden
        statusBarAnimation = animation
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func setStatusBarStyle(_ style: UIStatusBarStyle, animation: UIStatusBarAnimation = .fade) {
        statusBarStyle = style
        statusBarAnimation = animation
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func setNeedsUpdateStatusBar(_ animation: UIStatusBarAnimation = .fade) {
        statusBarAnimation = animation
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool { isStatusBarHidden }
    override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { statusBarAnimation }
}

// MARK: - 设备方向限制
extension MNBaseViewController {
    
    override var shouldAutorotate: Bool { false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
}
