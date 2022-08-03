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
    // 文件大小
    private let fileSizeLabel: UILabel = UILabel()
    // 原图选中标记
    private let fileSizeBadge: UIView = UIView()
    // 原图按钮
    private let fileSizeControl: UIControl = UIControl()
    
    init(options: MNAssetPickerOptions) {
        
        self.options = options
        disabledColor = options.mode == .light ? UIColor(white: 0.0, alpha: 0.12) : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
    
        super.init(frame: UIScreen.main.bounds.inset(by: UIEdgeInsets(top: UIScreen.main.bounds.height - options.toolbarHeight, left: 0.0, bottom: 0.0, right: 0.0)))
        
        if options.contentInset.bottom <= 0.0 {
            minY = UIScreen.main.bounds.height
        }
        
        if options.mode == .light {
            backgroundColor = .white.withAlphaComponent(0.97)
        } else {
            backgroundColor = .clear
            let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            effectView.frame = bounds
            effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(effectView)
        }
        
        clearButton.isEnabled = false
        clearButton.frame = CGRect(x: 16.0, y: 0.0, width: 50.0, height: 32.0)
        clearButton.setTitle("清空", for: .normal)
        clearButton.setTitleColor(options.color, for: .normal)
        clearButton.setTitleColor(disabledColor, for: .disabled)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16.0)
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
        doneButton.setTitle("完成", for: .normal)
        doneButton.maxX = width - clearButton.minX
        doneButton.titleLabel?.font = .systemFont(ofSize: 15.0)
        doneButton.setTitleColor(UIColor(red:251.0/255.0, green:251.0/255.0, blue:251.0/255.0, alpha:1.0), for: .normal)
        doneButton.setTitleColor(options.mode == .light ? UIColor(red:251.0/255.0, green:251.0/255.0, blue:251.0/255.0, alpha:1.0) : .white.withAlphaComponent(0.5), for: .disabled)
        doneButton.setBackgroundImage(UIImage(color: options.color), for: .normal)
        doneButton.setBackgroundImage(UIImage(color: disabledColor), for: .disabled)
        doneButton.contentHorizontalAlignment = .center
        doneButton.contentVerticalAlignment = .center
        doneButton.layer.cornerRadius = 4.0
        doneButton.clipsToBounds = true
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        addSubview(doneButton)
        
        fileSizeLabel.numberOfLines = 1
        fileSizeLabel.textAlignment = .left
        fileSizeLabel.font = .systemFont(ofSize: 13.0)
        fileSizeLabel.isUserInteractionEnabled = false
        fileSizeLabel.isHidden = (options.isShowFileSize == false && options.isAllowsOriginalExport == false)
        addSubview(fileSizeLabel)
        
        fileSizeControl.size = CGSize(width: 18.0, height: 18.0)
        fileSizeControl.midY = doneButton.midY
        fileSizeControl.clipsToBounds = true
        fileSizeControl.layer.borderWidth = 1.5
        fileSizeControl.layer.cornerRadius = fileSizeControl.bounds.height/2.0
        fileSizeControl.isHidden = options.isAllowsOriginalExport == false
        fileSizeControl.addTarget(self, action: #selector(updateOriginal), for: .touchUpInside)
        addSubview(fileSizeControl)
        
        fileSizeBadge.frame = fileSizeControl.bounds.inset(by: UIEdgeInsets(top: 3.0, left: 3.0, bottom: 3.0, right: 3.0))
        fileSizeBadge.clipsToBounds = true
        fileSizeBadge.isUserInteractionEnabled = false
        fileSizeBadge.layer.cornerRadius = fileSizeBadge.bounds.height/2.0
        fileSizeControl.addSubview(fileSizeBadge)
        
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
        
        updateFileSize([])
    }
    
    @objc func updateOriginal() {
        options.isOriginalExport = !options.isOriginalExport
        fileSizeLabel.textColor = options.isOriginalExport ? options.color : disabledColor
        fileSizeControl.layer.borderColor = fileSizeLabel.textColor?.cgColor
        fileSizeBadge.backgroundColor = fileSizeLabel.textColor
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
        var title: String = assets.count > 0 ? "(\(assets.count))" : ""
        title = "确定\(title)"
        let maxX = doneButton.maxX
        var width: CGFloat = (title as NSString).size(withAttributes: [.font:doneButton.titleLabel!.font!]).width
        width = ceil(width) + 15.0
        doneButton.width = width
        doneButton.maxX = maxX
        doneButton.setTitle(title, for: .normal)
        clearButton.isEnabled = assets.count > 0
        previewButton.isEnabled = assets.count > 0
        doneButton.isEnabled = (assets.count > 0 && assets.count >= options.minPickingCount)
        updateFileSize(assets)
    }
    
    private func updateFileSize(_ assets: [MNAsset]) {
        guard fileSizeLabel.isHidden == false else { return }
        var title: String = "原图"
        if options.isShowFileSize {
            let fileSize: [Int] = assets.compactMap { $0.fileSize }
            let sum: Int = fileSize.reduce(0, +)
            title = sum > 0 ? sum.fileSizeValue : "0.0M"
        }
        fileSizeLabel.text = title
        fileSizeLabel.sizeToFit()
        fileSizeLabel.height = ceil(fileSizeLabel.height)
        fileSizeLabel.width = ceil(fileSizeLabel.width) + 10.0
        fileSizeLabel.maxX = doneButton.minX
        fileSizeLabel.midY = doneButton.midY
        fileSizeLabel.textColor = options.isOriginalExport ? options.color : disabledColor
        guard options.isAllowsOriginalExport else { return }
        fileSizeControl.maxX = fileSizeLabel.minX - 5.0
        fileSizeControl.layer.borderColor = fileSizeLabel.textColor?.cgColor
        fileSizeBadge.backgroundColor = fileSizeLabel.textColor
    }
}
