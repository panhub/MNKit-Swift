//
//  ContactViewController.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/22.
//  联系人

import UIKit

class ContactViewController: MNListViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

// MARK: - Tab
extension ContactViewController {
    override var isRootViewController: Bool { true }
    override var tabBarItemTitle: String? { "通讯录" }
    override var tabBarItemImage: UIImage? { UIImage(named: "tab-contact") }
    override var tabBarItemSelectedImage: UIImage? { UIImage(named: "tab-contact-highlight") }
    override var tabBarItemTitleFont: UIFont { .systemFont(ofSize: 12.0, weight: .medium) }
    override var tabBarItemTitleColor: UIColor { UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) }
    override var tabBarItemSelectedTitleColor: UIColor { .black }
}
