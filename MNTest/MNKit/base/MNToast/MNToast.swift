//
//  MNToast.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/9/10.
//  弹窗定义

import UIKit
import ObjectiveC.runtime

class MNToast: UIView {
    /**关联弹窗的Key*/
    struct AssociatedKey {
        static var toast = "com.mn.toast.associated.key"
    }
    /**定义样式*/
    enum ToastStyle: String {
        case info = "MNInfoToast"
        case error = "MNErrorToast"
        case mask = "MNMaskToast"
        case shape = "MNShapeToast"
        case activity = "MNActivityToast"
        case message = "MNMsgToast"
        case progress = "MNProgressToast"
        case complete = "MNCompleteToast"
    }
    /**颜色*/
    @objc enum ToastEffect: Int {
        case dark, light, none
    }
    /**显示的位置 相对于Window而言*/
    @objc enum ToastPosition: Int {
        case top, center, bottom
    }
    // 颜色
    @objc static var effect: ToastEffect = .dark
    // 相对于位置的纵向偏移
    @objc static var offset: CGFloat = 0.0
    // 文字/画笔颜色
    @objc static var tintColor: UIColor = UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
    // 弹窗颜色
    @objc static var contentColor: UIColor = MNToast.effect == .light ? .white : (MNToast.effect == .dark ? .clear : .black)
    // 背景颜色
    @objc static var backgroundColor: UIColor = .clear
    // 字体
    @objc static var font: UIFont = UIFont.systemFont(ofSize: 16.8, weight: .regular)
    // 弹窗内容间隔
    @objc static var contentInset: UIEdgeInsets = UIEdgeInsets(top: 15.0, left: 13.0, bottom: 10.0, right: 13.0)
    // 最小持续时长
    @objc static var minimumDismissTimeInterval: CGFloat = 1.5
    // 最大持续时长
    @objc static var maximumDismissTimeInterval: CGFloat = .greatestFiniteMagnitude
    // 位置
    @objc static var position: ToastPosition = .center
    // 是否根据键盘状态调整位置
    @objc static var isAdjustsWhenKeyboardChange: Bool = false
    // 当需要根据键盘状态调整位置时与键盘间隔
    @objc static var contentKeyboardMargin: CGFloat = 15.0
    // 是否允许Toast期间交互
    @objc static var isUserInteractionEnabled: Bool = false
    // 消失动画时间
    @objc static var fadeAnimationDuration: TimeInterval = 0.2
    // 是否允许交互
    var isAllowsUserInteraction: Bool { Self.isUserInteractionEnabled == false }
    // 样式
    private(set) var style: ToastStyle = .message
    // 命名空间
    private static let nameSpace: String? = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String
    // 提示信息
    private var message: String?
    // 记录键盘位置
    private var keyboardFrame: CGRect = CGRect(x: 0.0, y: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height), width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    // 文字描述
    lazy var attributes: [NSAttributedString.Key: Any] = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 1.0
        paragraph.paragraphSpacing = 1.0
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacingBefore = 1.0
        var attributes = [NSAttributedString.Key: Any]()
        attributes[.paragraphStyle] = paragraph
        attributes[.font] = Self.font
        attributes[.foregroundColor] = Self.tintColor
        return attributes
    }()
    // 富文本信息
    var string: NSAttributedString? {
        guard let message = message, message.count > 0 else { return nil }
        return NSAttributedString(string: message, attributes: attributes)
    }
    // 弹窗内容
    lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 8.0
        contentView.isUserInteractionEnabled = false
        contentView.backgroundColor = Self.contentColor
        switch Self.effect {
        case .dark:
            let effect = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            effect.frame = contentView.bounds
            effect.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.addSubview(effect)
        case .light:
            let effect = UIView()
            effect.frame = contentView.bounds
            effect.backgroundColor = UIColor(white: 0.0, alpha: 0.12)
            effect.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.addSubview(effect)
        default: break
        }
        addSubview(contentView)
        return contentView
    }()
    // 提示信息
    lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        contentView.addSubview(label)
        return label
    }()
    // 提示图案
    lazy var container: UIView = {
        let container = UIView()
        contentView.addSubview(container)
        return container
    }()
    
    // 禁止外部直接实例化
    private override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Self.backgroundColor
        isUserInteractionEnabled = isAllowsUserInteraction
        if Self.isAdjustsWhenKeyboardChange {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardChangeFrame(_:)), name: UIApplication.keyboardWillChangeFrameNotification, object: nil)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if Self.isAdjustsWhenKeyboardChange {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // 实例化
    class func toast(style: ToastStyle, status: String? = nil) -> MNToast? {
        guard let nameSpace = MNToast.nameSpace else { return nil }
        guard let cls = NSClassFromString("\(nameSpace).\(style.rawValue)") as? MNToast.Type else { return nil }
        let toast = cls.init()
        toast.style = style
        toast.message = status
        toast.createView()
        return toast
    }
    
    // 创建子视图
    func createView() {}
    
    // 开始动画
    func start() {}
    
    // 停止动画
    @objc func stop() {}
    
    // 取消事件
    func cancel() {}
    
    // 更新提示信息
    func update(status msg: String?) {
        message = msg
        updateSubviews()
    }
    
    func update() {
        contentView.frame = current
    }
    
    // 约束子视图
    func updateSubviews() {
        label.attributedText = string
        if let attributedText = label.attributedText {
            container.minY = Self.contentInset.top
            var size = attributedText.boundingRect(with: CGSize(width: 175.0, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).size
            size.width = ceil(size.width)
            size.height = ceil(size.height)
            label.size = size
            label.minY = container.maxY + 8.0
            contentView.height = max(label.maxY, container.maxY) + Self.contentInset.bottom
            contentView.width = max(max(label.width, container.width) + Self.contentInset.left + Self.contentInset.right, contentView.height)
        } else {
            label.frame = .zero
            let width = container.width + max(Self.contentInset.left, Self.contentInset.right)*2.0
            let height = container.height + max(Self.contentInset.top, Self.contentInset.bottom)*2.0
            contentView.width = max(width, height)
            contentView.height = max(width, height)
            container.midY = contentView.height/2.0
        }
        label.midX = contentView.width/2.0
        container.midX = contentView.width/2.0
        update()
    }
    
    class func duration(status: String?) -> CGFloat {
        let minimum: CGFloat = max(CGFloat(status?.count ?? 0)*0.06 + 0.5, self.minimumDismissTimeInterval)
        return min(minimum, self.maximumDismissTimeInterval)
    }
    
    // 拒绝事件响应
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    // 关联弹窗
    override func willMove(toSuperview newSuperview: UIView?) {
        if let superview = newSuperview {
            objc_setAssociatedObject(superview, &MNToast.AssociatedKey.toast, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else if let superview = superview {
            objc_setAssociatedObject(superview, &MNToast.AssociatedKey.toast, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        super.willMove(toSuperview: newSuperview)
    }
}

// MARK: - 显示
extension MNToast {
    func show(in view: UIView? = MNToast.window) {
        if let _ = superview { return }
        guard let superview = view else { return }
        frame = superview.bounds
        superview.addSubview(self);
        createView()
        updateSubviews()
        start()
    }
}

// MARK: - 获取当前状态位置
private extension MNToast {
    var current: CGRect {
        var rect = contentView.bounds
        rect.origin.x = (bounds.width - rect.width)/2.0
        switch Self.position {
        case .top:
            rect.origin.y = 0.0
        case .center:
            rect.origin.y = (bounds.height - rect.height)/2.0
        case .bottom:
            rect.origin.y = bounds.height - rect.height
        }
        rect.origin.y += Self.offset;
        if keyboardFrame.minY < UIScreen.main.bounds.height, let window = window {
            // 键盘弹出状态
            let keyboardRect = window.convert(keyboardFrame, to: self)
            rect.origin.y = min(keyboardRect.minY - rect.height - Self.contentKeyboardMargin, rect.minY)
        }
        return rect
    }
}

// MARK: - 键盘变化通知
extension MNToast {
    @objc private func keyboardChangeFrame(_ notify: Notification) {
        guard let userInfo = notify.userInfo else { return }
        guard let frame = userInfo[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        keyboardFrame = frame
        guard let _ = window else { return }
        let contentRect = current
        guard contentView.frame != contentRect else { return }
        let duration: TimeInterval = userInfo[UIWindow.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        /*
        let curve = UIView.AnimationCurve(rawValue: (userInfo[UIWindow.keyboardAnimationCurveUserInfoKey] as? Int ?? UIView.AnimationCurve.easeInOut.rawValue))
        var options: UIView.AnimationOptions = [.beginFromCurrentState, .curveEaseInOut]
        switch curve {
        case .easeInOut:
            options = options.union(.curveEaseInOut)
        case .easeIn:
            options = options.union(.curveEaseIn)
        case .easeOut:
            options = options.union(.curveEaseOut)
        case .linear:
            options = options.union(.curveLinear)
        default:
            options = options.union(.curveLinear)
        }
        */
        // 更新位置
        UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            self?.contentView.center = CGPoint(x: contentRect.midX, y: contentRect.midY)
        } completion: { _ in }
    }
}
