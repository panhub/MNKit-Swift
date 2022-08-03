//
//  TLMineViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  我的

import UIKit

class TLMineViewController: MNListViewController {
    /// 模型
    private var rows: [TLMineModel] = [TLMineModel]()
    /// 列表样式
    override var listType: MNListViewController.ListType { .table }
    
    override init() {
        super.init()
        edges = []
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationBar.translucent = false
        navigationBar.backgroundColor = .clear
        navigationBar.shadowView.isHidden = true
        
        contentView.backgroundColor = VIEW_COLOR
        
        tableView.frame = contentView.bounds
        tableView.separatorStyle = .none
        tableView.backgroundColor = VIEW_COLOR
        tableView.rowHeight = 50.0
        //tableView.register(TLMineTableCell.self, forCellReuseIdentifier: MNCollectionElement.Identifier.cell)
        tableView.tableHeaderView = TLMineHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.width, height: 0.0))
    }
    
    override func loadData() {
        let icons: [String] = ["mine-favorite", "mine-version", "mine-logout"]
        let titles: [String] = ["我的收藏", "版本号", "退出"]
        let events: [TLMineModel.Event] = [.favorite, .version, .logout]
        for (idx, icon) in icons.enumerated() {
            let model = TLMineModel()
            model.title = titles[idx]
            model.icon = icon
            model.event = events[idx]
            rows.append(model)
        }
        reloadList()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - Navigation
extension TLMineViewController {
    
    func numberOfSections(in tableView: UITableView) -> Int { rows.count }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section > 0 ? 10.0 : 0.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: MNCollectionElement.Identifier.cell) ?? TLMineTableCell(reuseIdentifier: MNCollectionElement.Identifier.cell, size: CGSize(width: tableView.width, height: tableView.rowHeight))
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section < rows.count else { return }
        (cell as? TLMineTableCell)?.update(row: rows[indexPath.section])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < rows.count else { return }
        let row = rows[indexPath.section]
        switch row.event {
        case .favorite:
            break
        case .version:
            break
        case .logout:
            let alertView = MNAlertView(title: nil, message: "确定退出登录?")
            alertView.addAction(title: "取消", style: .cancel, handler: nil)
            alertView.addAction(title: "退出", style: .destructive) { _ in
                
            }
            alertView.show()
        }
        
    }
}

// MARK: - Navigation
extension TLMineViewController {
    
    override func navigationBarShouldCreateLeftBarItem() -> UIView? {
        let leftBarButton = UIButton(type: .custom)
        leftBarButton.size = CGSize(width: 25.0, height: 25.0)
        leftBarButton.setBackgroundImage(UIImage(named: "back"), for: .normal)
        leftBarButton.addTarget(self, action: #selector(navigationBarLeftBarItemTouchUpInside(_:)), for: .touchUpInside)
        return leftBarButton
    }
}

