//
//  MNAssetAlbumView.swift
//  MNFoundation
//
//  Created by 冯盼 on 2022/1/31.
//  相簿选择视图

import UIKit

protocol MNAssetAlbumViewDelegate: NSObjectProtocol {
    /**相册点击事件*/
    func albumView(_ albumView: MNAssetAlbumView, didSelectAlbum album: MNAssetAlbum?) -> Void
}

class MNAssetAlbumView: UIView {
    // 是否在显示
    var isShow: Bool { isHidden }
    // 数据源
    var albums: [MNAssetAlbum] = [MNAssetAlbum]()
    // 配置信息
    private let options: MNAssetPickerOptions
    // 显示相簿
    private let tableView: UITableView = UITableView(frame: .zero, style: .plain)
    // 事件代理
    weak var delegate: MNAssetAlbumViewDelegate?
    
    init(options: MNAssetPickerOptions) {
        
        self.options = options
        
        super.init(frame: UIScreen.main.bounds.inset(by: options.contentInset))
        
        isHidden = true
        clipsToBounds = true
        backgroundColor = .clear
        
        tableView.frame = bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 63.0
        tableView.backgroundColor = options.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.width, height: CGFloat.leastNormalMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.width, height: 10.0))
        tableView.separatorColor = options.mode == .light ? .gray.withAlphaComponent(0.15) : .black.withAlphaComponent(0.85)
        tableView.estimatedSectionFooterHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        addSubview(tableView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        tap.delegate = self
        tap.numberOfTouchesRequired = 1
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(albums: [MNAssetAlbum]) {
        let rowHeight = tableView.rowHeight
        let footerHeight = tableView.tableFooterView?.bounds.height ?? 0.0
        var count: Int = min(7, albums.count)
        var height: CGFloat = rowHeight*CGFloat(count)
        let max: CGFloat = ceil(bounds.height/4.0*3.0)
        if height > max {
            count = Int((max - footerHeight)/CGFloat(rowHeight))
            height = rowHeight*CGFloat(count)
        }
        self.albums.removeAll()
        self.albums.append(contentsOf: albums)
        tableView.height = height
        tableView.maxY = 0.0
        tableView.reloadData()
    }
    
    func reloadData() { tableView.reloadData() }
    
    @objc func tap() {
        delegate?.albumView(self, didSelectAlbum: nil)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MNAssetAlbumView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { albums.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "com.mn.asset.album.cell") ?? MNAssetAlbumCell(reuseIdentifier: "com.mn.asset.album.cell", size: CGSize(width: tableView.bounds.width, height: tableView.rowHeight), options: options)
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < albums.count, let albumCell = cell as? MNAssetAlbumCell else { return }
        albumCell.update(album: albums[indexPath.row])
    }
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let albumCell = cell as? MNAssetAlbumCell else { return }
        albumCell.didEndDisplaying()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < albums.count else { return }
        let album = albums[indexPath.row]
        guard album.isSelected == false else { return }
        for (index, obj) in albums.enumerated() {
            obj.isSelected = index == indexPath.row
        }
        tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.15) { [weak self] in
            guard let self = self else { return }
            self.delegate?.albumView(self, didSelectAlbum: album)
        }
    }
}

// MARK: - Show & Dismiss
extension MNAssetAlbumView {
    func show(completion: (()->Void)? = nil) {
        guard isHidden else { return }
        isHidden = false
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            self.tableView.minY = 0.0
            self.backgroundColor = .black.withAlphaComponent(0.43)
        } completion: { _ in
            completion?()
        }
    }
    
    func dismiss(completion: (()->Void)? = nil) {
        guard isHidden == false else { return }
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut) { [weak self] in
            guard let self = self else { return }
            self.tableView.maxY = 0.0
            self.backgroundColor = .clear
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.isHidden = true
            completion?()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MNAssetAlbumView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else { return false }
        return view == self
    }
}

