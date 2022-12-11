//
//  extensions.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 27/07/21.
//

import UIKit

extension UIColor {
    static let displayRed = UIColor(0xE61A25)
    static let displayGray = UIColor(0x333333)
    
    static let scoreboardDark = UIColor(0x1A1A1A)
    static let scoreboard = UIColor(0x242424)
    
    static let appGreen = UIColor(0x37800B)
    static let appLightGreen = UIColor(0xD7F3C6)
    
    
    convenience init(_ hex: Int) {
        self.init(
            red: CGFloat((Float((hex & 0xff0000) >> 16)) / 255.0),
            green: CGFloat((Float((hex & 0x00ff00) >> 8)) / 255.0),
            blue: CGFloat((Float((hex & 0x0000ff) >> 0)) / 255.0),
            alpha: 1.0)
    }
}

extension Array where Element: Equatable {
    func randomElements(_ numberOfElements: Int) -> [Element] {
        if (numberOfElements >= count) { return self}
        var result = [Element]()
        while result.count < numberOfElements {
            let v = randomElement()
            if v != nil && !result.contains(where: { $0 == v }) { result.append(v!) }
        }
        return result
    }
}

extension String {
    func padLeft(_ n: Int, _ value: Character) -> String {
        var r = self
        while r.count < n { r.insert(value, at: r.startIndex) }
        return r
    }
}

extension UILabel {
    func animateTime(from: Int = 0, to: Int, withDuration: TimeInterval = 1) {
        let numbers = from...to
        let numberDelay = withDuration / Double(numbers.count)
        for (index, number) in numbers.enumerated() {
            let deadline = Double(index) * numberDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + deadline) {
                self.text = intToTimeString(Double(number))
            }
        }
    }
}
