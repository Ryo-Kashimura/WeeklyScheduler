//
//  utils.swift
//  DiceScheduler
//
//  Created by 鹿志村諒 on 2019/07/16.
//  Copyright © 2019年 Team Time Efficiency. All rights reserved.
//

import UIKit
import Foundation

extension Date {
    var weekday: String {
        let calendar = Calendar(identifier: .gregorian)
        let component = calendar.component(.weekday, from: self)
        let weekday = component - 1
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja")
        return formatter.shortWeekdaySymbols[weekday]
    }
}

class DayInner: Equatable, ExpressibleByStringLiteral {
    
    let dateString: String
    
    var isToWork: Bool = true

    required init(stringLiteral elements: String) {
        self.dateString = elements
    }

    typealias StringLiteralElement = String

    static func == (lhs: DayInner, rhs: DayInner) -> Bool {
        return lhs.dateString == rhs.dateString
    }
    
}

enum Day: DayInner {
    
    case sunday = "2019/07/14 09:00"
    case monday = "2019/07/15 09:00"
    case tuesday = "2019/07/16 09:00"
    case wednesday = "2019/07/17 09:00"
    case thursday = "2019/07/18 09:00"
    case friday = "2019/07/19 09:00"
    case saturday = "2019/07/20 09:00"
    
    var jaStyleSymbol: String {
        get {
            let day2JaStyleSymbol: [Day: String] = [
                .sunday: "日", .monday: "月", .tuesday: "火", .wednesday: "水", .thursday: "木", .friday: "金", .saturday: "土"
            ]
            guard let daySymbol = day2JaStyleSymbol[self] else {
                return ""
            }
            return daySymbol
        }
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat) {
        let v = Int("000000" + hex, radix: 16) ?? 0
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
    }
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha: 1.0)
    }
}
