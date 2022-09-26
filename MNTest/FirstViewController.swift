//
//  FirstViewController.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/24.
//

import UIKit

class FirstViewController: MNBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let b = MNButton(frame: CGRect(x: 0.0, y: 0.0, width: 150.0, height: 46.0))
        b.backgroundColor = .red
        b.imageView.image = UIImage(named: "clean_icon")
        b.imageView.width = 18.0
        b.imageView.sizeFitToWidth()
        b.titleLabel.font = .systemFont(ofSize: 16.0, weight: .medium)
        b.titleLabel.text = "测试删除表格"
        b.titleLabel.textColor = .white
        b.layer.cornerRadius = 5.0
        b.clipsToBounds = true
        b.center = contentView.Center
        b.distribution = .firstImage
        b.alignment = .center
        b.addTarget(self, action: #selector(pick), for: .touchUpInside)
        contentView.addSubview(b)
    }
    
    @objc func pick() {
        //navigationController?.pushViewController(ViewController(), animated: true)
        let picker = MNAssetPicker()
        picker.options.mode = .dark
        picker.options.isAllowsPreview = true
        picker.options.isShowFileSize = false
        picker.options.maxPickingCount = 10
        picker.options.isAllowsPickingGif = false
        picker.options.isAllowsPickingPhoto = false
        picker.options.isAllowsPickingLivePhoto = false
        picker.options.maxPickingCount = 1
        picker.present { [weak self] _, assets in
            guard let self = self else { return }
            let vc = MNTailorViewController(videoPath: assets.first!.content as! String)
            //vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
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

//extension FirstViewController: MNTailorViewControllerDelegate {
//
//    func tailorControllerDidCancel() {
//        print("--------")
//    }
//}
