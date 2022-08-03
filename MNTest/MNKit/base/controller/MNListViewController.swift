//
//  MNListViewController.swift
//  MNFoundation
//
//  Created by 冯盼 on 2021/8/5.
//  数据流控制器

import UIKit

@objc class MNListViewController: MNExtendViewController {
    /**数据流视图类型*/
    @objc enum ListType: Int {
        case table, grid
    }
    /**表格类型*/
    @objc var listType: ListType { .table }
    /**是否需要刷新列表*/
    private var isNeedReloadList: Bool = false
    /**是否可以下拉刷新*/
    @objc var isRefreshEnabled: Bool = false
    /**是否可以加载更多*/
    @objc var isLoadMoreEnabled: Bool = false
    /**空数据视图的父视图*/
    override var emptySuperview: UIView { listView }
    /**空数据视图位置 这里不使用listView是为了避免刷新时inset变化导致视图错位*/
    override var emptyViewFrame: CGRect { CGRect(x: 0.0, y: 0.0, width: listView.frame.width, height: listView.frame.height) }
    /**表格样式*/
    @objc var tableStyle: UITableView.Style { .plain }
    /**瀑布流约束*/
    @objc var collectionViewLayout: UICollectionViewLayout {
        let layout = MNCollectionViewFlowLayout()
        layout.numberOfColumns = 2;
        layout.minimumLineSpacing = 10.0;
        layout.minimumInteritemSpacing = 10.0
        layout.itemSize = CGSize(width: 1.0, height: 1.0)
        return layout;
    }
    /**瀑布流*/
    @objc lazy var collectionView: UICollectionView = {
        let collectionView = customizedCollectionView()// UICollectionView.collection(frame: contentView.bounds, layout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        insertRefreshHeader(to: collectionView)
        insertLoadFooter(to: collectionView)
        return collectionView
    }()
    /**表*/
    @objc lazy var tableView: UITableView = {
        let tableView = customizedTableView()//UITableView.table(frame: contentView.bounds, style: tableStyle)
        tableView.delegate = self
        tableView.dataSource = self
        insertRefreshHeader(to: tableView)
        insertLoadFooter(to: tableView)
        return tableView
    }()
    /**外界获取滑动视图*/
    @objc var listView: UIScrollView { listType == .table ? tableView : collectionView }
    /**定制刷新控件*/
    @objc var listHeader: MNRefreshHeader {
        return MNRefreshNormalHeader(style: (view.frame.minY + contentView.frame.minY == 0.0) ? .margin : .normal)
    }
    /**定制加载更多控件*/
    @objc var listFooter: MNRefreshFooter {
        return MNRefreshAutoFooter(style: (view.frame.minY + contentView.frame.maxY == UIScreen.main.bounds.height) ? .margin : .normal)
    }
    
    override func createView() {
        super.createView()
        contentView.addSubview(listView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadListIfNeeded()
    }
    
    /**刷新表格*/
    @objc func reloadList() -> Void {
        if listType == .table {
            tableView.reloadData()
        } else {
            collectionView.reloadData()
        }
    }
    
    /**刷新表格*/
    @objc func setNeedsReloadList() {
        isNeedReloadList = true
    }
    
    /**刷新表格*/
    @objc func reloadListIfNeeded() {
        guard isNeedReloadList else { return }
        isNeedReloadList = false
        reloadList()
    }
    
    @objc func willMove(refreshHeader: MNRefreshHeader, to listView: UIScrollView) {}
    @objc func willMove(loadFooter: MNRefreshFooter, to listView: UIScrollView) {}
    override func prepare(request: HTTPPageRequest) {
        if contentView.existToast == false, listView.isRefreshing == false, listView.isLoadMore == false {
            contentView.showToast(status: "请稍后")
        }
    }
    override func finish(request: HTTPPageRequest) {
        reloadList()
        endRefrshing()
        super.finish(request: request)
    }
    
    /// 适配项目
    /// - Returns: 定制表格控件
    func customizedTableView() -> UITableView {
        return UITableView(frame: contentView.bounds, tableStyle: tableStyle)
    }
    
    /// 适配项目
    /// - Returns: 定制表格控件
    func customizedCollectionView() -> UICollectionView {
        return UICollectionView(frame: contentView.bounds, layout: collectionViewLayout)
    }
}

// MARK: - 下拉刷新, 加载更多
extension MNListViewController {
    
    @objc func insertRefreshHeader(to listView: UIScrollView) {
        guard isRefreshEnabled, listView.refresh_header == nil else { return }
        let header = listHeader
        header.addTarget(self, action: #selector(refresh))
        willMove(refreshHeader: header, to: listView)
        listView.refresh_header = header
    }
    
    @objc func insertLoadFooter(to listView: UIScrollView) {
        guard isLoadMoreEnabled, listView.load_footer == nil else { return }
        let footer = listFooter
        footer.state = .noMoreData
        footer.addTarget(self, action: #selector(loadMore))
        willMove(loadFooter: footer, to: listView)
        listView.load_footer = footer
    }
    
    @objc private func refresh() {
        guard listView.isLoadMore == false else {
            listView.endRefreshing()
            return
        }
        beginRefresh()
    }
    
    @objc private func loadMore() {
        guard listView.isRefreshing == false else {
            listView.endLoadMore()
            return
        }
        beginLoadMore()
    }
    
    @objc func beginRefresh() {
        guard let request = httpRequest, request.isLoading == false else {
            listView.endRefreshing()
            return
        }
        reloadData()
    }
    
    @objc func beginLoadMore() {
        guard let request = httpRequest, request.isLoading == false else {
            listView.endLoadMore()
            return
        }
        loadData()
    }
    
    @objc func endRefrshing() {
        listView.endLoadMore()
        listView.endRefreshing()
        guard let request = httpRequest else { return }
        if request.hasMore {
            resetLoadFooter()
        } else {
            noMoreData()
        }
    }
    
    @objc func resetLoadFooter() {
        guard let footer = listView.load_footer else { return }
        if footer.state == .noMoreData {
            footer.resetNoMoreData()
        } else if footer.isRefreshing {
            footer.endRefreshing()
        }
    }
    
    @objc func noMoreData() {
        listView.noMoreData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MNListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return CGFloat.leastNormalMagnitude }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { return CGFloat.leastNormalMagnitude }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { nil }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(false, "请实现'tableView:cellForRowAt:'代理方法")
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, MNCollectionViewLayoutDelegate
extension MNListViewController: UICollectionViewDelegate, UICollectionViewDataSource, MNCollectionViewLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 0 }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        assert(false, "请实现'collectionView:cellForItemAt:'代理方法")
        return collectionView.dequeueReusableCell(withReuseIdentifier: MNCollectionElement.Identifier.cell, for: indexPath)
    }
}
