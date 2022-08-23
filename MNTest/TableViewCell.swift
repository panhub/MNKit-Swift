//
//  TableViewCell.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/23.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    var bg: UIView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        contentView.backgroundColor = .white
        
        let view = UIView(frame: contentView.bounds.inset(by: UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)))
        view.layer.cornerRadius = 8.0
        view.clipsToBounds = true
        view.backgroundColor = .gray.withAlphaComponent(0.2)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(view)
        
        bg = view
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutEditingView()
    }
    
//    init(reuseIdentifier: String?, size: CGSize) {
//        super.init(style: .default, reuseIdentifier: reuseIdentifier)
//
//        selectionStyle = .none
//
//        self.size = size
//
//        contentView.backgroundColor = .white
//        contentView.frame = bounds
//        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        let view = UIView(frame: contentView.bounds.inset(by: UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)))
//        view.layer.cornerRadius = 8.0
//        view.clipsToBounds = true
//        view.backgroundColor = .gray.withAlphaComponent(0.2)
//        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        contentView.addSubview(view)
//
//        bg = view
//    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
