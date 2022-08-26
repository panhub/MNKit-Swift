//
//  ViewController.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/2.
//

import UIKit

class ViewController: MNListViewController {
    
    //override func navigationBarShouldDrawBackBarItem() -> Bool { false }
    
    override init() {
        super.init()
        statusBarStyle = .lightContent
        title = "测试编辑"
    }
    
    override var listType: MNListViewController.ListType { .grid }
    
    override var collectionViewLayout: UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: contentView.frame.width, height: 75.0)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        return layout
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
        tableView.editingOptions.cornerRadius = 8.0
        tableView.editingOptions.contentInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: MNCollectionElement.Identifier.cell)
        collectionView.editingOptions.cornerRadius = 8.0
        collectionView.editingOptions.contentInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }
}

extension ViewController {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 50 }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: MNCollectionElement.Identifier.cell, for: indexPath)
    }
}

extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 50 }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: MNCollectionElement.Identifier.cell)
        if cell == nil {
            cell = TableViewCell(style: .default, reuseIdentifier: MNCollectionElement.Identifier.cell)
            cell.allowsEditing = true
        }
        return cell
    }
}

extension ViewController: UICollectionViewEditingDelegate {
    
    func collectionView(_ collectionView: UICollectionView, editingActionsForRowAt indexPath: IndexPath) -> [UIView] {
        let button0 = UIButton(type: .custom)
        button0.size = CGSize(width: 80.0, height: 55.0)
        button0.backgroundColor = .purple
        button0.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button0.setTitle("置顶", for: .normal)
        button0.setTitleColor(.white, for: .normal)
        button0.contentVerticalAlignment = .center
        button0.contentHorizontalAlignment = .center
        
        let button = UIButton(type: .custom)
        button.size = CGSize(width: 80.0, height: 55.0)
        button.backgroundColor = .red
        button.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button.setTitle("删除", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        
        let button2 = UIButton(type: .custom)
        button2.size = CGSize(width: 80.0, height: 55.0)
        button2.backgroundColor = .blue
        button2.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button2.setTitle("备注", for: .normal)
        button2.setTitleColor(.white, for: .normal)
        button2.contentVerticalAlignment = .center
        button2.contentHorizontalAlignment = .center
        return [button0, button, button2]
    }
    
    func collectionView(_ collectionView: UICollectionView, commitEditing action: UIView, forRowAt indexPath: IndexPath) -> UIView? {
        let button = UIButton(type: .custom)
        button.size = CGSize(width: 180.0, height: 55.0)
        button.backgroundColor = action.backgroundColor
        button.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button.setTitle("确认删除", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        return button
    }
    
    func collectionView(_ collectionView: UICollectionView, rowEditingDirectionAt indexPath: IndexPath) -> MNEditingDirection {
        indexPath.row%2 == 0 ? .left : .right
    }
}

extension ViewController: UITableViewEditingDelegate {
    
    func tableView(_ tableView: UITableView, rowEditingDirectionAt indexPath: IndexPath) -> MNEditingDirection {
        indexPath.row%2 == 0 ? .left : .right
    }
    
    func tableView(_ tableView: UITableView, editingActionsForRowAt indexPath: IndexPath) -> [UIView] {
        
        let button0 = UIButton(type: .custom)
        button0.size = CGSize(width: 80.0, height: 55.0)
        button0.backgroundColor = .purple
        button0.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button0.setTitle("置顶", for: .normal)
        button0.setTitleColor(.white, for: .normal)
        button0.contentVerticalAlignment = .center
        button0.contentHorizontalAlignment = .center
        
        let button = UIButton(type: .custom)
        button.size = CGSize(width: 80.0, height: 55.0)
        button.backgroundColor = .red
        button.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button.setTitle("删除", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        
        let button2 = UIButton(type: .custom)
        button2.size = CGSize(width: 80.0, height: 55.0)
        button2.backgroundColor = .blue
        button2.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button2.setTitle("备注", for: .normal)
        button2.setTitleColor(.white, for: .normal)
        button2.contentVerticalAlignment = .center
        button2.contentHorizontalAlignment = .center
        return [button0, button, button2]
    }
    
    func tableView(_ tableView: UITableView, commitEditing action: UIView, forRowAt indexPath: IndexPath) -> UIView? {
        let button = UIButton(type: .custom)
        button.size = CGSize(width: 180.0, height: 55.0)
        button.backgroundColor = action.backgroundColor
        button.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        button.setTitle("确认删除", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        return button
    }
}

