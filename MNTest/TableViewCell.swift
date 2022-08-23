//
//  TableViewCell.swift
//  MNTest
//
//  Created by 冯盼 on 2022/8/23.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        contentView.backgroundColor = .white
        
        let view = UIView(frame: contentView.bounds.inset(by: UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)))
        view.layer.cornerRadius = 8.0
        view.clipsToBounds = true
        view.backgroundColor = .gray.withAlphaComponent(0.3)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(view)
    }
    
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
