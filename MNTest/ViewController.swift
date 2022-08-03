//
//  ViewController.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/2.
//

import UIKit

class ViewController: MNBaseViewController {
    
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
        
        contentView.backgroundColor = .red
        
    }
}

