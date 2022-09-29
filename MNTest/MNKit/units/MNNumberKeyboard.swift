//
//  MNNumberKeyboard.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/28.
//  数字键盘

import UIKit

@objc protocol MNNumberKeyboardDelegate: NSObjectProtocol {
    
    @objc optional func numberKeyboard(_ keyboard: MNNumberKeyboard, shouldClick key: MNNumberKeyboard.Key) -> Bool
    //
    @objc optional func numberKeyboardTextDidChange(_ keyboard: MNNumberKeyboard) -> Void
    
    @objc optional func numberKeyboardReturnButtonClicked(_ keyboard: MNNumberKeyboard) -> Void
}

class MNNumberKeyboard: UIView {
    
    @objc enum Key: Int {
        case zero, one, two, three, four, five, six, seven, eight, nine, decimal, done, delete, space
    }
    
    enum KeyType {
        case none, decimal, done, delete
    }
    
    /// 输入结果
    private(set) var text: String = ""
    /// 按键间隔
    var spacing: CGFloat = 1.5
    /// 是否可以输入小数点
    var decimalCapable: Bool = true
    /// 按键标题字体
    var titleFont: UIFont?
    /// 是否乱序排列数字
    var isScramble: Bool = false
    /// 左键类型
    var leftKeyType: KeyType = .decimal
    /// 右键类型
    var rightKeyType: KeyType = .done
    /// 按键标题颜色
    var titleColor: UIColor?
    /// 按键背景颜色
    var keyBackgroundColor: UIColor?
    /// 按键高亮颜色
    var keyHighlightedColor: UIColor?
    /// 事件代理
    weak var delegate: MNNumberKeyboardDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 1.0))
        
        backgroundColor = UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if let _ = newSuperview, subviews.count <= 0 {
            reloadKeys()
        }
        super.willMove(toSuperview: newSuperview)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let _ = superview, subviews.count <= 0 {
            reloadKeys()
        }
    }
    
    func reloadKeys() {
        
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        let columns: Int = 3
        let height: CGFloat = 55.0
        let spacing: CGFloat = max(spacing, 0.0)
        let width: CGFloat = ceil((frame.width - spacing*CGFloat(columns - 1))/CGFloat(columns))
        let titleFont = titleFont ?? .systemFont(ofSize: 20.0, weight: .medium)
        let titleColor = titleColor ?? .black
        let backgroundImage = UIImage(color: keyBackgroundColor ?? .white)
        let highlightedImage = UIImage(color: keyHighlightedColor ?? UIColor(red: 169.0/255.0, green: 169.0/255.0, blue: 169.0/255.0, alpha: 1.0))
        var keys: [MNNumberKeyboard.Key] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine]
        if isScramble {
            for index in 1..<keys.count {
                let random = Int(arc4random_uniform(100000)) % index
                if random != index {
                    keys.swapAt(index, random)
                }
            }
        }
        keys.appendKey(type: leftKeyType)
        keys.append(.zero)
        keys.appendKey(type: rightKeyType)
        
        CGRect(x: 0.0, y: spacing, width: width, height: height).grid(offset: UIOffset(horizontal: spacing, vertical: spacing), count: keys.count, column: columns) { idx, rect, _ in
            
            let key = keys[idx]
            guard key != .space else { return }
            
            var button: UIButton
            if #available(iOS 15.0, *) {
                var attributedTitle = AttributedString(key.title)
                attributedTitle.font = key == .decimal ? .systemFont(ofSize: 37.0, weight: .bold) : titleFont
                attributedTitle.foregroundColor = titleColor
                var configuration = UIButton.Configuration.plain()
                configuration.attributedTitle = attributedTitle
                button = UIButton(configuration: configuration)
                button.configurationUpdateHandler = { sender in
                    switch sender.state {
                    case .normal:
                        sender.configuration?.background.image = backgroundImage
                    case .highlighted:
                        sender.configuration?.background.image = highlightedImage
                    default: break
                    }
                }
            } else {
                let attributedTitle = NSMutableAttributedString(string: key.title)
                attributedTitle.addAttribute(.foregroundColor, value: titleColor, range: NSRange(location: 0, length: attributedTitle.length))
                attributedTitle.addAttribute(.font, value: key == .decimal ? .systemFont(ofSize: 37.0, weight: .bold) : titleFont, range: NSRange(location: 0, length: attributedTitle.length))
                button = UIButton(type: .custom)
                button.clipsToBounds = true
                button.layer.cornerRadius = 5.0
                button.setAttributedTitle(attributedTitle, for: .normal)
                button.setBackgroundImage(backgroundImage, for: .normal)
                button.setBackgroundImage(highlightedImage, for: .highlighted)
            }
            button.tag = key.rawValue
            button.frame = rect
            button.addTarget(self, action: #selector(keyButtonTouchUpInside(_:)), for: .touchUpInside)
            addSubview(button)
        }
        
        self.height = (height + spacing)*ceil(CGFloat(keys.count)/CGFloat(columns)) + MN_TAB_SAFE_HEIGHT
    }
    
    @objc private func keyButtonTouchUpInside(_ sender: UIButton) {
        UIDevice.current.playInputClick()
        guard let key = MNNumberKeyboard.Key(rawValue: sender.tag) else { return }
        guard (delegate?.numberKeyboard?(self, shouldClick: key) ?? true) == true else { return }
        // 确定按钮
        if key == .done {
            delegate?.numberKeyboardReturnButtonClicked?(self)
            return
        }
        // 删除
        if key == .delete {
            if text.count > 0 {
                text.removeLast()
                delegate?.numberKeyboardTextDidChange?(self)
            }
            return
        }
        // 不可直接输入小数点或重复输入小数点
        if key == .decimal {
            guard text.count > 0, text.contains(".") == false else { return }
        }
        // 追加字符
        let string = key.desc
        text.append(string)
        delegate?.numberKeyboardTextDidChange?(self)
    }
}

extension MNNumberKeyboard {
    
    func setFont(_ font: UIFont, forKey key: MNNumberKeyboard.Key) {
        for subview in subviews {
            guard let k: MNNumberKeyboard.Key = MNNumberKeyboard.Key(rawValue: subview.tag) else { continue }
            guard k == key else { continue }
            guard let button = subview as? UIButton else { break }
            if #available(iOS 15.0, *) {
                guard var attributedTitle = button.configuration?.attributedTitle  else { break }
                attributedTitle.font = font
                button.configuration?.attributedTitle = attributedTitle
                button.updateConfiguration()
            } else {
                guard let attributedString = button.attributedTitle(for: .normal)  else { break }
                let attributedTitle = NSMutableAttributedString(attributedString: attributedString)
                attributedTitle.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedTitle.length))
                button.setAttributedTitle(attributedTitle, for: .normal)
            }
        }
    }
    
    func setTitle(_ title: String, forKey key: MNNumberKeyboard.Key) {
        for subview in subviews {
            guard let k: MNNumberKeyboard.Key = MNNumberKeyboard.Key(rawValue: subview.tag) else { continue }
            guard k == key else { continue }
            guard let button = subview as? UIButton else { break }
            if #available(iOS 15.0, *) {
                guard let attributedString = button.configuration?.attributedTitle  else { break }
                var attributedTitle = AttributedString(title)
                attributedTitle.font = attributedString.font
                attributedTitle.foregroundColor = attributedString.foregroundColor
                button.configuration?.attributedTitle = attributedTitle
                button.updateConfiguration()
            } else {
                guard let attributedString = button.attributedTitle(for: .normal)  else { break }
                let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
                let attributedTitle = NSAttributedString(string: title, attributes: attributes)
                button.setAttributedTitle(attributedTitle, for: .normal)
            }
        }
    }
}

extension MNNumberKeyboard: UIInputViewAudioFeedback {
    
    var enableInputClicksWhenVisible: Bool { true }
}

extension MNNumberKeyboard.Key {
    
    var title: String {
        guard self == .decimal else { return desc }
        return "·"
    }
    
    var desc: String {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .decimal: return "."
        case .done: return "done"
        case .delete: return "delete"
        case .space: return ""
        }
    }
}

fileprivate extension Array where Element == MNNumberKeyboard.Key {
    
    mutating func appendKey(type: MNNumberKeyboard.KeyType) {
        switch type {
        case .decimal:
            append(.decimal)
        case .delete:
            append(.delete)
        case .done:
            append(.done)
        case .none:
            append(.space)
        }
    }
}
