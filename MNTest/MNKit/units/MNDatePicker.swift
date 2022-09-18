//
//  MNDatePicker.swift
//  MNTest
//
//  Created by 冯盼 on 2022/9/16.
//

import UIKit

fileprivate extension MNDatePicker.Module {
    
    var isFull: Bool {
        switch self {
        case .year(full: let flag, suffix: _): return flag
        case .month(full: let flag, en: _, suffix: _): return flag
        case .day(full: let flag, suffix: _): return flag
        case .hour(full: let flag, clock12: _, suffix: _): return flag
        case .minute(full: let flag, suffix: _): return flag
        case .second(full: let flag, suffix: _): return flag
        default: return false
        }
    }
    
    var suffix: String {
        switch self {
        case .spacing(let suffix): return suffix
        case .year(full: _, suffix: let suffix): return suffix
        case .month(full: _, en: _, suffix: let suffix): return suffix
        case .day(full: _, suffix: let suffix): return suffix
        case .hour(full: _, clock12: _, suffix: let suffix): return suffix
        case .minute(full: _, suffix: let suffix): return suffix
        case .second(full: _, suffix: let suffix): return suffix
        default: return ""
        }
    }
    
    var isEn: Bool {
        switch self {
        case .month(full: _, en: let flag, suffix: _): return flag
        default: return false
        }
    }
    
    var is12HourClock: Bool {
        switch self {
        case .hour(full: _, clock12: let flag, suffix: _): return flag
        default: return false
        }
    }
}

extension Array where Element == MNDatePicker.Module {
    
    var year: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .year(full: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    var month: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .month(full: _, en: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    var day: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .day(full: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    var hour: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .hour(full: _, clock12: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    var minute: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .minute(full: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
    
    var second: MNDatePicker.Module? {
        for element in self {
            switch element {
            case .second(full: _, suffix: _): return element
            default: break
            }
        }
        return nil
    }
}

class MNDatePicker: UIView {
    
    struct Time {
        var year: String = ""
        var month: String = ""
        var day: String = ""
        var hour: String = ""
        var minute: String = ""
        var second: String = ""
    }
    
    enum Module {
        case stage
        case spacing(String)
        case year(full: Bool, suffix: String)
        case month(full: Bool, en: Bool, suffix: String)
        case day(full: Bool, suffix: String)
        case hour(full: Bool, clock12: Bool, suffix: String)
        case minute(full: Bool, suffix: String)
        case second(full: Bool, suffix: String)
    }
    
    private class Component {
        
        let module: MNDatePicker.Module
        
        var rows: [String] = [String]()
        
        var width: CGFloat = 0.0
        
        init(module: MNDatePicker.Module) {
            self.module = module
        }
    }
    
    /// 字体
    var font: UIFont = .systemFont(ofSize: 16.0, weight: .medium)
    /// 字体颜色
    var textColor: UIColor = .black
    /// 组件
    var modules: [Module] = [.year(full: true, suffix: "-"), .month(full: false, en: true, suffix: "-"), .day(full: true, suffix: ""), .hour(full: true, clock12: true, suffix: ":"), .minute(full: true, suffix: ":"), .second(full: true, suffix: "")]
    /// 最早的时间
    var minimumDate: Date = Date(timeIntervalSince1970: 0.0)
    /// 最晚的时间
    var maximumDate: Date = Date()
    /// 行高
    var rowHeight: CGFloat = 40.0
    /// 记录当时时间
    private var time: Time = Time()
    /// 选择器
    private let picker = UIPickerView()
    /// 组件
    private var components: [Component] = [Component]()
    /// 格式化
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 3600*8)
        return formatter
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        picker.frame = bounds
        picker.delegate = self
        picker.dataSource = self
        picker.tintColor = UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 220.0/255.0, alpha: 1.0)
        addSubview(picker)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadComponents() {
        
        if minimumDate >= maximumDate {
            minimumDate = Date(timeIntervalSince1970: 0.0)
        }
        if maximumDate == minimumDate {
            maximumDate = Date()
        }
        
        formatter.dateFormat = "yyyy MM dd HH mm ss"
        let times = formatter.string(from: maximumDate).components(separatedBy: " ")
        time.year = times[0]
        time.month = times[1]
        time.day = times[2]
        time.hour = times[3]
        time.minute = times[4]
        time.second = times[5]
        
        // 年
        components.removeAll()
        if let module = modules.year {
            
            formatter.dateFormat = "yyyy"
            
            let minYear: Int = NSDecimalNumber(string: formatter.string(from: minimumDate)).intValue
            let maxYear: Int = NSDecimalNumber(string: formatter.string(from: maximumDate)).intValue
            
            let isFull: Bool = module.isFull
            let component = Component(module: module)
            component.width = ceil(((isFull ? "0000" : "00") as NSString).size(withAttributes: [.font:font]).width) + 15.0
            for year in minYear...maxYear {
                let string: String = "\(year)"
                if isFull {
                    component.rows.append(string)
                } else {
                    component.rows.append((string as NSString).substring(from: 2))
                }
            }
            components.append(component)
            
            if module.suffix.count > 0 {
                let m = Component(module: .spacing(module.suffix))
                m.width = ceil((module.suffix as NSString).size(withAttributes: [.font:font]).width)
                m.rows.append(module.suffix)
                components.append(m)
            }
        }
        
        // 月
        if let module = modules.month {
            
            let isEn: Bool = module.isEn
            let isFull: Bool = module.isFull
            let months: [String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            let abbrs: [String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            let component = Component(module: module)
            component.width = ceil(((isEn ? "November" : "00") as NSString).size(withAttributes: [.font:font]).width) + 15.0
            if isEn {
                let array: [String] = isFull ? months : abbrs
                let width = array.reduce(0.0, { partialResult, string in
                    let w = (string as NSString).size(withAttributes: [.font:font]).width
                    return max(w, partialResult)
                })
                component.width = ceil(width) + 10.0
            } else {
                component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 15.0
            }
            for month in 0..<12 {
                var string: String = ""
                if isEn {
                    if isFull {
                        string.append(months[month])
                    } else {
                        string.append(abbrs[month])
                    }
                } else {
                    if isFull, month < 9 {
                        string.append("0")
                    }
                    string.append("\(month + 1)")
                }
                component.rows.append(string)
            }
            components.append(component)
            if module.suffix.count > 0 {
                let m = Component(module: .spacing(module.suffix))
                m.width = ceil((module.suffix as NSString).size(withAttributes: [.font:font]).width)
                m.rows.append(module.suffix)
                components.append(m)
            }
        }
        
        // 日
        if let module = modules.day {
            
            let isFull: Bool = module.isFull
            let component = Component(module: module)
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 15.0
            for day in 0..<31 {
                var string: String = "\(day + 1)"
                if isFull, string.count == 1 {
                    string = "0" + string
                }
                component.rows.append(string)
            }
            components.append(component)
            
            if module.suffix.count > 0 {
                let m = Component(module: .spacing(module.suffix))
                m.width = ceil((module.suffix as NSString).size(withAttributes: [.font:font]).width)
                m.rows.append(module.suffix)
                components.append(m)
            }
        }
        
        // 时
        if let module = modules.hour {
            
            let isFull: Bool = module.isFull
            let is12HourClock: Bool = module.is12HourClock
            
            if is12HourClock {
                // 时段
                let component = Component(module: .stage)
                component.width = ceil(((isFull ? "AM" : "M") as NSString).size(withAttributes: [.font:font]).width) + 15.0
                if isFull {
                    component.rows.append(contentsOf: ["AM", "PM"])
                } else {
                    component.rows.append(contentsOf: ["A", "P"])
                }
                components.append(component)
            }
            
            let component = Component(module: module)
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 8.0
            let begin: Int = is12HourClock ? 1 : 0
            let end: Int = is12HourClock ? 13 : 24
            for hour in begin..<end {
                var string: String = "\(hour)"
                if isFull, string.count == 1 {
                    string = "0" + string
                }
                component.rows.append(string)
            }
            components.append(component)
            
            if module.suffix.count > 0 {
                let m = Component(module: .spacing(module.suffix))
                m.width = ceil((module.suffix as NSString).size(withAttributes: [.font:font]).width)
                m.rows.append(module.suffix)
                components.append(m)
            }
        }
        
        // 分
        if let module = modules.minute {
            
            let isFull: Bool = module.isFull
            let component = Component(module: module)
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 8.0
            for minute in 0..<60 {
                var string: String = "\(minute)"
                if isFull, string.count == 1 {
                    string = "0" + string
                }
                component.rows.append(string)
            }
            components.append(component)
            
            if module.suffix.count > 0 {
                let m = Component(module: .spacing(module.suffix))
                m.width = ceil((module.suffix as NSString).size(withAttributes: [.font:font]).width)
                m.rows.append(module.suffix)
                components.append(m)
            }
        }
        
        // 秒
        if let module = modules.second {
            
            let isFull: Bool = module.isFull
            let component = Component(module: module)
            component.width = ceil(("00" as NSString).size(withAttributes: [.font:font]).width) + 8.0
            for second in 0..<60 {
                var string: String = "\(second)"
                if isFull, string.count == 1 {
                    string = "0" + string
                }
                component.rows.append(string)
            }
            components.append(component)
            
            if module.suffix.count > 0 {
                let m = Component(module: .spacing(module.suffix))
                m.width = ceil((module.suffix as NSString).size(withAttributes: [.font:font]).width)
                m.rows.append(module.suffix)
                components.append(m)
            }
        }
    }
    
    private func layoutPicker() {
        var rect: CGRect = .zero
        rect.size.width = components.reduce(0.0, { $0 + $1.width })
        rect.size.width += (min(frame.width - rect.width, 100.0))
        rect.size.height = frame.height
        rect.origin.x = (frame.width - rect.width)/2.0
        picker.frame = rect
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        reloadComponents()
        layoutPicker()
        picker.reloadAllComponents()
        super.willMove(toSuperview: newSuperview)
    }
}

extension MNDatePicker {
    
    func selectDate(_ date: Date, animated: Bool) {
        
        let selectDate: Date = min(max(minimumDate, date), maximumDate)
        
        
        
        
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension MNDatePicker: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { components.count }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { components[component].rows.count }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat { components[component].width }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { rowHeight }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel = (view as? UILabel) ?? UILabel()
        label.font = font
        label.numberOfLines = 1
        label.textColor = textColor
        label.textAlignment = .center
        label.text = components[component].rows[row]
        label.sizeToFit()
        return label
    }
}
