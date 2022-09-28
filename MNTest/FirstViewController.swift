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
        b.spacing = 5.0
        b.imageView.image = UIImage(named: "clean_icon")
        b.imageView.width = 15.0
        b.imageView.sizeFitToWidth()
        b.titleLabel.font = .systemFont(ofSize: 16.0, weight: .medium)
        b.titleLabel.text = "测试删除表格"
        b.titleLabel.textColor = .white
        //b.layer.cornerRadius = 5.0
        b.clipsToBounds = true
        b.center = contentView.Center
        b.imagePlacement = .leading
        b.contentInset = UIEdgeInsets(top: 13.0, left: 15.0, bottom: 13.0, right: 15.0)
        b.sizeToFit()
        b.addTarget(self, action: #selector(pick), for: .touchUpInside)
        contentView.addSubview(b)
        
        let pageControl = MNPageControl()
        pageControl.spacing = 10.0
        pageControl.numberOfPages = 5
        //pageControl.pageIndicatorTintColor = .red
        pageControl.backgroundColor = UIColor(all: 245.0)
        contentView.addSubview(pageControl)
        pageControl.midX = b.midX
        pageControl.minY = b.maxY + 20.0
        pageControl.layer.cornerRadius = pageControl.height/2.0
    }
    
    @objc func pick() {
        
        let alert = MNActionSheet(title: "测试操作表单", message: "测试操作表单哦哦哦")
        alert.addAction(title: "确定", style: .cancel) { _ in
            
        }
        alert.addAction(title: "取消", style: .default) { _ in
            
        }
        alert.addAction(title: "取消", style: .destructive) { _ in
            
        }
        alert.show()
        return
        //navigationController?.pushViewController(ViewController(), animated: true)
        let picker = MNAssetPicker()
        picker.options.mode = .dark
        picker.options.isAllowsEditing = true
        picker.options.isAllowsPreview = true
        picker.options.isShowFileSize = false
        picker.options.maxPickingCount = 10
        picker.options.isAllowsPickingGif = true
        picker.options.isAllowsPickingPhoto = true
        picker.options.isAllowsPickingLivePhoto = true
        picker.options.isAllowsMultiplePickingVideo = false
        picker.present { [weak self] _, assets in
//            guard let self = self else { return }
//            let vc = MNTailorViewController(videoPath: assets.first!.content as! String)
//            vc.delegate = self
//            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //view.showProgressToast("测试进度", progress: 0.35)
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

extension FirstViewController: MNTailorControllerDelegate {

    func tailorControllerDidCancel() {
        print("--------")
    }
    
    func tailorController(_ tailorController: MNTailorViewController, didTailorVideoAtPath videoPath: String) {
        print(videoPath)
    }
}
