//
//  MNNumberKeyboard.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/28.
//  数字键盘

import UIKit

class MNNumberKeyboard: UIView {
    
    enum Number: Int {
        case zero, one, two, three, four, five, six, seven, eight, nine, decimal, done
        
        var desc: String {
            switch self {
            case .zero: return "0"
            case .one: return "1"
            case .two: return "2"
            case .three: return "3"
            case .four: return "4"
            case .five: return "5"
            case .six: return "6"
            case .seven: return "7"
            case .eight: return "8"
            case .nine: return "9"
            case .decimal: return "."
            case .done: return "done"
            }
        }
    }
    
    var text: String = ""
    
    var spacing: CGFloat = 1.5
    
    var decimalCapable: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 0.0))
        
        backgroundColor = UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func reloadData() {
        
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        let columns: Int = 3
        let height: CGFloat = 55.0
        let width: CGFloat = ceil((frame.width - spacing*CGFloat(columns - 1))/CGFloat(columns))
        let numbers: [Number] = [.one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .decimal, .zero, .done]
        CGRect(x: 0.0, y: 0.0, width: width, height: height).grid(offset: UIOffset(horizontal: spacing, vertical: spacing), count: 10, column: columns) { idx, rect, _ in
            
            let button = UIButton(type: .custom)
            button.frame = rect
            button.tag = numbers[idx].rawValue
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 21.0, weight: .medium)
            addSubview(button)
            
        }
    }
}
