//
//  MNAssetPickerToolBar.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/30.
//  资源选择器底部控制栏

import UIKit

protocol MNAssetPickerToolDelegate: NSObjectProtocol {
    /**清除已选事件回调*/
    func clearButtonTouchUpInside(_ toolBar: MNAssetPickerToolBar) -> Void
    /**预览事件回调*/
    func previewButtonTouchUpInside(_ toolBar: MNAssetPickerToolBar) -> Void
    /**确定事件回调*/
    func doneButtonTouchUpInside(_ toolBar: MNAssetPickerToolBar) -> Void
}

class MNAssetPickerToolBar: UIView {
    // 按钮无效颜色
    private let disabledColor: UIColor
    // 配置信息
    private let options: MNAssetPickerOptions
    // 原图按钮
    weak var delegate: MNAssetPickerToolDelegate?
    // 清除
    private let clearButton: UIButton = UIButton(type: .custom)
    // 确定
    private let doneButton: UIButton = UIButton(type: .custom)
    // 预览
    private let previewButton: UIButton = UIButton(type: .custom)
    
    init(options: MNAssetPickerOptions) {
        
        self.options = options
        disabledColor = options.mode == .light ? UIColor(white: 0.0, alpha: 0.12) : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
    
        super.init(frame: UIScreen.main.bounds.inset(by: UIEdgeInsets(top: UIScreen.main.bounds.height - options.toolBarHeight, left: 0.0, bottom: 0.0, right: 0.0)))
        
        backgroundColor = .clear
        isHidden = options.contentInset.bottom <= 0.0
        
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: options.mode == .light ? .extraLight : .dark))
        effectView.frame = bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(effectView)
        
        clearButton.isEnabled = false
        clearButton.frame = CGRect(x: 16.0, y: 0.0, width: 50.0, height: 32.0)
        clearButton.setTitle("清空", for: .normal)
        clearButton.setTitleColor(options.color, for: .normal)
        clearButton.setTitleColor(disabledColor, for: .disabled)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16.0, weight: .medium)
        clearButton.contentHorizontalAlignment = .left
        clearButton.contentVerticalAlignment = .center
        clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
        if MN_TAB_SAFE_HEIGHT > 0.0 {
            clearButton.maxY = bounds.height - MN_TAB_SAFE_HEIGHT
        } else {
            clearButton.midY = bounds.midY
        }
        addSubview(clearButton)
        
        previewButton.isEnabled = false
        previewButton.frame = clearButton.frame
        previewButton.midX = bounds.midX
        previewButton.setTitle("预览", for: .normal)
        previewButton.setTitleColor(options.color, for: .normal)
        previewButton.setTitleColor(disabledColor, for: .disabled)
        previewButton.titleLabel?.font = clearButton.titleLabel?.font
        previewButton.contentVerticalAlignment = .center
        previewButton.contentHorizontalAlignment = .center
        previewButton.isHidden = options.isAllowsPreview == false
        previewButton.addTarget(self, action: #selector(preview), for: .touchUpInside)
        addSubview(previewButton)
        
        doneButton.isEnabled = false
        doneButton.frame = clearButton.frame
        doneButton.setTitle("确定", for: .normal)
        doneButton.maxX = width - clearButton.minX
        doneButton.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        doneButton.setTitleColor(UIColor(red:251.0/255.0, green:251.0/255.0, blue:251.0/255.0, alpha:1.0), for: .normal)
        doneButton.setTitleColor(options.mode == .light ? UIColor(red:251.0/255.0, green:251.0/255.0, blue:251.0/255.0, alpha:1.0) : .white.withAlphaComponent(0.5), for: .disabled)
        doneButton.setBackgroundImage(UIImage(color: options.color), for: .normal)
        doneButton.setBackgroundImage(UIImage(color: disabledColor), for: .disabled)
        doneButton.clipsToBounds = true
        doneButton.layer.cornerRadius = 4.0
        doneButton.contentVerticalAlignment = .center
        doneButton.contentHorizontalAlignment = .center
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        addSubview(doneButton)
        
        let separator = UIView(frame: CGRect(x: 0.0, y: 0.0, width: bounds.width, height: 0.7))
        separator.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        separator.backgroundColor = options.mode == .light ? .gray.withAlphaComponent(0.15) : .black.withAlphaComponent(0.85)
        addSubview(separator)
        
        if options.isAllowsPreview {
            previewButton.contentHorizontalAlignment = .left
            previewButton.minX = clearButton.frame.minX
            clearButton.contentHorizontalAlignment = .center
            clearButton.midX = bounds.midX
        } else {
            previewButton.isHidden = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Event
extension MNAssetPickerToolBar {
    @objc func clear() {
        delegate?.clearButtonTouchUpInside(self)
    }
    @objc func preview() {
        delegate?.previewButtonTouchUpInside(self)
    }
    @objc func done() {
        delegate?.doneButtonTouchUpInside(self)
    }
}

// MARK: - Update
extension MNAssetPickerToolBar {
    
    func update(assets: [MNAsset]) {
        var suffix: String
        if options.isShowFileSize {
            let fileSize: Int64 = assets.reduce(0) { $0 + max($1.fileSize, 0) }
            suffix = fileSize > 0 ? fileSize.fileSizeValue : ""
        } else {
            suffix = assets.count > 0 ? "\(assets.count)" : ""
        }
        let title = suffix.count > 0 ? "确定(\(suffix))" : "确定"
        let string = NSMutableAttributedString(string: title)
        string.addAttribute(.font, value: doneButton.titleLabel!.font!, range: NSRange(location: 0, length: string.length))
        string.addAttribute(.foregroundColor, value: doneButton.titleColor(for: (assets.count > 0 && assets.count >= options.minPickingCount) ? .normal : .disabled)!, range: NSRange(location: 0, length: string.length))
        string.addAttribute(.font, value: options.isShowFileSize ? UIFont.systemFont(ofSize: 12.0, weight: .medium) : doneButton.titleLabel!.font!, range: (title as NSString).range(of: suffix))
        let maxX = doneButton.maxX
        let width = ceil(string.boundingRect(with: CGSize(width: 1000.0, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size.width)
        doneButton.width = width + 15.0
        doneButton.maxX = maxX
        doneButton.setAttributedTitle(string, for: .normal)
        doneButton.setAttributedTitle(string, for: .disabled)
        clearButton.isEnabled = assets.count > 0
        previewButton.isEnabled = assets.count > 0
        doneButton.isEnabled = (assets.count > 0 && assets.count >= options.minPickingCount)
    }
}
