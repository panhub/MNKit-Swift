//
//  TLHomeCourseView.swift
//  TLChat
//
//  Created by 冯盼 on 2022/7/21.
//  首页教程

import UIKit

class TLHomeCourseView: UIView {
    
    private let firstView: UIImageView = UIImageView(image: UIImage(named: "home-course-1"))
    
    private let bindView: UIImageView = UIImageView(image: UIImage(named: "home-course-2"))
    
    private let ensureButton: UIButton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        
        backgroundColor = .black.withAlphaComponent(0.45)
        
        firstView.width = 230.0
        firstView.sizeFitToWidth()
        addSubview(firstView)
        
        bindView.isHidden = true
        bindView.width = firstView.width
        bindView.sizeFitToWidth()
        addSubview(bindView)
        
        ensureButton.titleLabel?.font = .systemFont(ofSize: 16.0, weight: .regular)
        ensureButton.setTitle("知道了", for: .normal)
        ensureButton.setTitleColor(.white, for: .normal)
        ensureButton.sizeToFit()
        ensureButton.height = 35.0
        ensureButton.width = ceil(ensureButton.width) + 40.0
        ensureButton.clipsToBounds = true
        ensureButton.layer.cornerRadius = 3.0
        ensureButton.layer.borderWidth = 1.5
        ensureButton.layer.borderColor = UIColor.white.cgColor
        ensureButton.contentVerticalAlignment = .center
        ensureButton.contentHorizontalAlignment = .center
        ensureButton.addTarget(self, action: #selector(backgroundTouchUpInside), for: .touchUpInside)
        addSubview(ensureButton)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTouchUpInside))
        tap.numberOfTapsRequired = 1
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layout(rect: CGRect) {
        
        firstView.minY = rect.maxY - floor(rect.height/4.0)
        firstView.midX = rect.midX
        
        bindView.minY = firstView.minY
        bindView.midX = firstView.midX
        
        ensureButton.midX = firstView.midX
        ensureButton.minY = firstView.maxY + 40.0
    }
    
    @objc private func backgroundTouchUpInside() {
        if bindView.isHidden {
            firstView.isHidden = true
            bindView.isHidden = false
        } else {
            removeFromSuperview()
            TLHelper.helper.isShowHomeCourse = false
        }
    }
}
