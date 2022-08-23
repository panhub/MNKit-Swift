//
//  ViewController.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/2.
//

import UIKit

class ViewController: MNListViewController {
    
    override func navigationBarShouldDrawBackBarItem() -> Bool { false }
    
    override init() {
        super.init()
        statusBarStyle = .lightContent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.rowHeight = 75.0
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.options.contentInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        tableView.options.cornerRadius = 8.0
    }
}

extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: MNCollectionElement.Identifier.cell)
        if cell == nil {
            cell = TableViewCell(style: .default, reuseIdentifier: MNCollectionElement.Identifier.cell)
            cell?.allowsEditing = true
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        cell.contentView.frame = CGRect(x: -100.0, y: 0.0, width: cell.width, height: cell.height)
    }
}

extension ViewController: UITableViewEditingDelegate {
    
    func tableView(_ tableView: UITableView, rowEditingDirectionAt indexPath: IndexPath) -> UITableViewCell.EditingDirection {
        indexPath.row%2 == 0 ? .left : .right
    }
    
    func tableView(_ tableView: UITableView, canEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingActionsForRowAt indexPath: IndexPath) -> [UIView] {
        let button = UIButton(type: .custom)
        button.size = CGSize(width: 80.0, height: 55.0)
        button.backgroundColor = .red
        button.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button.setTitle("删除", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        
        let button2 = UIButton(type: .custom)
        button2.size = CGSize(width: 100.0, height: 55.0)
        button2.backgroundColor = .blue
        button2.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button2.setTitle("备注", for: .normal)
        button2.setTitleColor(.white, for: .normal)
        button2.contentVerticalAlignment = .center
        button2.contentHorizontalAlignment = .center
        return [button, button2]
    }
    
    func tableView(_ tableView: UITableView, commitEditing action: UIView, forRowAt indexPath: IndexPath) -> UIView? {
        let button = UIButton(type: .custom)
        button.size = CGSize(width: 180.0, height: 55.0)
        button.backgroundColor = .red
        button.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button.setTitle("确认删除", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        return button
    }
}

