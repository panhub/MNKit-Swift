//
//  MNAlertQueue.swift
//  tiescreen
//
//  Created by 冯盼 on 2022/7/8.
//  弹窗

import UIKit

protocol MNAlertStringConvertible {}
extension String: MNAlertStringConvertible {}
extension NSAttributedString: MNAlertStringConvertible {}
extension MNAlertStringConvertible {
    func attributedString(font: UIFont, color: UIColor) -> NSAttributedString {
        if self is NSAttributedString {
            return self as! NSAttributedString
        }
        return NSAttributedString(string: self as! String, attributes: [.font:font, .foregroundColor: color])
    }
}

/// 弹窗按钮
struct MNAlertAction {
    
    /// 标题样式
    enum Style : Int {
        // 默认按钮
        case `default` = 0
        // 取消
        case cancel = 1
        // 删除
        case destructive = 2
    }
    /// 样式
    let style: MNAlertAction.Style
    /// 事件回调
    private let handler: ((MNAlertAction)->Void)?
    /// 标题
    private let title: MNAlertStringConvertible
    /// 标题字体
    private let font: UIFont = .systemFont(ofSize: 16.0, weight: .medium)
    /// 颜色
    private var color: UIColor {
        switch style {
        case .cancel:
            return UIColor(red: 47.0/255.0, green: 124.0/255.0, blue: 246.0/255.0, alpha: 1.0)
        case .destructive:
            return UIColor(red: 255.0/255.0, green: 58.0/255.0, blue: 58.0/255.0, alpha: 1.0)
        default:
            return .darkText.withAlphaComponent(0.88)//.black
        }
    }
    /// 标题富文本
    var attributedTitle: NSAttributedString {
        title.attributedString(font: font, color: color)
    }
    
    /// 初始化按钮
    /// - Parameters:
    ///   - title: 标题
    ///   - style: 样式
    ///   - handler: 事件回调
    init(title: MNAlertStringConvertible, style: MNAlertAction.Style = .default, handler: ((MNAlertAction) -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
    
    /// 回调事件
    fileprivate func execute() {
        handler?(self)
    }
}

/// 关闭弹窗通知
let MNAlertCloseNotification: Notification.Name = Notification.Name(rawValue: "com.mn.alert.view.close")

class MNAlertQueue: UIView {
    /// 标题
    let title: MNAlertStringConvertible?
    /// 提示信息
    let message: MNAlertStringConvertible?
    /// 标题
    let titleLabel: UILabel = UILabel()
    /// 提示信息
    let textLabel: UILabel = UILabel()
    /// 内容视图
    let contentView: UIView = UIView()
    /// 事件集合
    private(set) var actions: [MNAlertAction] = [MNAlertAction]()
    /// 暂存弹窗
    fileprivate static var pool: [MNAlertQueue] = [MNAlertQueue]()
    
    /// 构造弹窗
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 提示信息
    init(title: MNAlertStringConvertible? = nil, message: MNAlertStringConvertible?) {
        self.title = title
        self.message = message
        super.init(frame: UIScreen.main.bounds)
        // 背景点击事件
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTouchUpInside))
        tap.delegate = self
        tap.numberOfTapsRequired = 1
        addGestureRecognizer(tap)
        // 注册关闭弹窗通知
        NotificationCenter.default.addObserver(self, selector: #selector(close), name: MNAlertCloseNotification, object: nil)
    }
    
    /// 快捷构造
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 提示信息
    ///   - cancelButtonTitle: 取消按钮标题
    ///   - destructiveButtonTitle: 删除按钮标题
    ///   - otherButtonTitles: 其它按钮标题
    ///   - clickedHandler: 事件回调
    convenience init(title: MNAlertStringConvertible? = nil, message: MNAlertStringConvertible? = nil, cancelButtonTitle: MNAlertStringConvertible? = nil, destructiveButtonTitle: MNAlertStringConvertible? = nil, otherButtonTitles: MNAlertStringConvertible?..., clicked clickedHandler: ((Int) -> Void)? = nil) {
        self.init(title: title, message: message)
        var elements: [(MNAlertAction.Style, MNAlertStringConvertible)] = [(MNAlertAction.Style, MNAlertStringConvertible)]()
        for otherButtonTitle in otherButtonTitles {
            guard let buttonTitle = otherButtonTitle else { break }
            elements.append((MNAlertAction.Style.default, buttonTitle))
        }
        if let buttonTitle = cancelButtonTitle {
            elements.append((MNAlertAction.Style.cancel, buttonTitle))
        }
        if let buttonTitle = destructiveButtonTitle {
            elements.append((MNAlertAction.Style.destructive, buttonTitle))
        }
        for (index, element) in elements.enumerated() {
            addAction(title: element.1, style: element.0) { _ in
                clickedHandler?(index)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 创建子视图
    func createViews() {
        fatalError("Must overwrite 'createViews'.")
    }
    
    /// 展示
    final func show() {
        guard superview == nil, actions.count > 0 else { return }
        guard let superview = UIWindow.current else { return }
        // 注销键盘
        superview.endEditing(true)
        // 取消当前
        if let alert = Self.pool.last, let _ = alert.superview {
            alert.endEditing(true)
            alert.removeFromSuperview()
        }
        // 显示当前
        autoresizingMask = []
        frame = superview.bounds
        backgroundColor = .clear
        if subviews.count <= 0 {
            createViews()
        }
        superview.addSubview(self)
        Self.pool.append(self)
        showAnimation()
    }
    
    /// 弹出动画
    func showAnimation() {
        fatalError("Must overwrite 'showAnimation'.")
    }
    
    /// 结束动画
    /// - Parameter action: 点击的按钮
    final func dismiss(clicked action: MNAlertAction? = nil) {
        dismissAnimation { [weak self] _ in
            if let self = self {
                self.close()
            }
            if let action = action {
                action.execute()
            }
            MNAlertQueue.next()
        }
    }
    
    /// 消失动画
    /// - Parameter completion: 动画结束回调
    func dismissAnimation(completion: @escaping (Bool) -> Void) {
        fatalError("Must overwrite 'dismissAnimation(completion:)'.")
    }
}

// MARK: - Events
extension MNAlertQueue {
    
    /// 按钮点击事件
    /// - Parameter sender: 按钮
    @objc final func actionButtonTouchUpInside(_ sender: UIView) {
        let action: MNAlertAction? = (actions.count > 0 && sender.tag < actions.count) ? actions[sender.tag] : nil
        dismiss(clicked: action)
    }
    
    /// 背景点击事件
    /// - Parameter recognizer: 点击对象
    @objc func backgroundTouchUpInside() {}
}

// MARK: - Add Components
extension MNAlertQueue {
    
    /// 添加按钮
    /// - Parameter action: 事件
    final func addAction(_ action: MNAlertAction) {
        if action.style == .cancel || action.style == .destructive {
            guard actions.filter ({ $0.style == action.style }).count <= 0 else { return }
        }
        actions.append(action)
    }
    
    /// 添加按钮
    /// - Parameters:
    ///   - title: 标题
    ///   - style: 样式
    ///   - handler: 事件回调
    final func addAction(title: MNAlertStringConvertible, style: MNAlertAction.Style = .default, handler: ((MNAlertAction) -> Void)? = nil) {
        addAction(MNAlertAction(title: title, style: style, handler: handler))
    }
    
    /// 内部更新按钮
    /// - Parameter actions: 按钮集合
    final func updateActions(_ actions: [MNAlertAction]) {
        self.actions.removeAll()
        self.actions.append(contentsOf: actions)
    }
}

// MARK: - Event
extension MNAlertQueue {
    
    /// 展示下一个弹窗
    final class func next() {
        guard let alert = pool.last else { return }
        pool.removeLast()
        alert.show()
    }
    
    /// 接收到关闭通知
    @objc final func close() {
        if let _ = superview {
            endEditing(true)
            removeFromSuperview()
        }
        if let index = Self.pool.firstIndex(of: self) {
            Self.pool.remove(at: index)
        }
    }
    
    /// 关闭所有弹窗
    final class func closeAll() {
        NotificationCenter.default.post(name: MNAlertCloseNotification, object: nil, userInfo: nil)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MNAlertQueue: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        return contentView.frame.contains(location) == false
    }
}
