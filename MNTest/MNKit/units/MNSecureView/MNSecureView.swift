//
//  MNSecureView.swift
//  anhe
//
//  Created by 冯盼 on 2022/5/5.
//

import UIKit

@objc protocol MNSecureViewDelegate: NSObjectProtocol {
    // 想要开始编辑
    @objc optional func secureViewShouldBeginEditing(_ secureView: MNSecureView) -> Bool
    // 已经开始编辑
    @objc optional func secureViewDidBeginEditing(_ secureView: MNSecureView)
    // 想要结束编辑
    @objc optional func secureViewShouldEndEditing(_ secureView: MNSecureView) -> Bool
    // 已经结束编辑
    @objc optional func secureViewDidEndEditing(_ secureView: MNSecureView)
}

class MNSecureView: UIView {
    // 输入框
    private let textField: UITextField = UITextField()
    // 密码位
    private var labels: [MNSecureLabel] = [MNSecureLabel]()
    // 密码位
    private var caches: [Int:MNSecureLabel] = [Int:MNSecureLabel]()
    // 是否可编辑
    var isAllowsEditing: Bool = true
    // 配置信息
    let options: MNSecureOptions = MNSecureOptions()
    // 事件代理
    weak var delegate: MNSecureViewDelegate?
    // 文字
    var text: String { textField.text ?? "" }
    // 键盘
    override var inputView: UIView? {
        get { textField.inputView }
        set { textField.inputView = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        textField.text = ""
        textField.delegate = self
        textField.isHidden = true
        //textField.frame = bounds
        //textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        addSubview(textField)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let _ = superview, options.capacity > 0 else { return }
        if options.capacity == labels.count { return }
        reloadSublabels()
    }
    
    private func layoutSublabels() {
        let width: CGFloat = (frame.width - options.interval*CGFloat(options.capacity - 1))/CGFloat(options.capacity)
        guard width > 1.0 else {
            #if DEBUG
            print("can not create secure label, because width too small.")
            #endif
            return
        }
        for index in 0..<options.capacity {
            let x: CGFloat = (width + options.interval)*CGFloat(index)
            let label = label(index: index)
            label.frame = CGRect(x: x, y: 0.0, width: width, height: frame.height)
            label.update(options: options)
            addSubview(label)
            caches.removeValue(forKey: label.index)
            labels.append(label)
        }
    }
    
    private func label(index: Int) -> MNSecureLabel {
        if let label = caches[index] { return label }
        let label = MNSecureLabel()
        label.index = index
        label.addTarget(self, action: #selector(textLabelTouchUpInside), for: .touchUpInside)
        caches[index] = label
        return label
    }
    
    private func update(text: String) {
        let labels: [MNSecureLabel] = self.labels.filter { $0.superview != nil }
        guard labels.count > 0 else { return }
        for index in 0..<labels.count {
            let label = labels[index]
            if index >= text.count {
                label.update(text: "")
            } else {
                let start = text.index(text.startIndex, offsetBy: index)
                let end = text.index(text.startIndex, offsetBy: index + 1)
                let character = String(text[start..<end])
                label.update(text: character)
            }
        }
    }
}

extension MNSecureView {
    
    /// 更新视图
    func reloadSublabels() {
        for label in labels {
            label.removeFromSuperview()
        }
        labels.removeAll()
        textField.text = ""
        textField.setMarkedText(nil, selectedRange: NSRange(location: 0, length: 0))
        textField.keyboardType = options.isNumberTextEntry ? .numberPad : .default
        layoutSublabels()
    }
    
    /// 追加字符
    /// - Parameter character: 指定字符
    /// - Returns: 是否追加成功
    func append(contentsOf character: String) -> Bool {
        textField.setMarkedText(nil, selectedRange: NSRange(location: 0, length: 0))
        var text: String = textField.text ?? ""
        guard labels.count > 0, character.count == 1, text.count + character.count <= options.capacity else { return false }
        text.append(contentsOf: character)
        textField.text = text
        update(text: text)
        return true
    }
    
    /// 删除所有文字
    func removeAll() {
        textField.text = ""
        textField.setMarkedText(nil, selectedRange: NSRange(location: 0, length: 0))
        update(text: "")
    }
}

extension MNSecureView: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard isAllowsEditing, (delegate?.secureViewShouldBeginEditing?(self) ?? true) else { return false }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.secureViewDidBeginEditing?(self)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard (delegate?.secureViewShouldEndEditing?(self) ?? true) else { return false }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.secureViewDidEndEditing?(self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard range.location + string.count <= options.capacity else { return false }
        return true
    }
}

extension MNSecureView {
    
    @objc private func textDidChange(_ textField: UITextField) {
        if let _ = textField.markedTextRange {
            // 候选文字改变
            #if DEBUG
            //print(markedRange)
            #endif
        } else {
            var text = textField.text ?? ""
            if text.count > options.capacity {
                let start = text.startIndex
                let end = text.index(text.startIndex, offsetBy: options.capacity)
                text = String(text[start..<end])
                textField.text = text
            }
            update(text: text)
        }
    }
    
    @objc private func textLabelTouchUpInside() {
        textField.becomeFirstResponder()
    }
}
