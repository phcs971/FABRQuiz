//
//  DisplayBackground.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 27/07/21.
//

import UIKit

@IBDesignable
class DisplayBackground: UIView {
    @IBInspectable
    var radius: CGFloat = 8 { didSet { self.layer.cornerRadius = self.radius } }
    
    @IBInspectable
    var borderWidth: CGFloat = 2 { didSet { self.layer.borderWidth = self.borderWidth } }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = .scoreboardDark
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.radius
        self.layer.borderWidth = self.borderWidth
    }
}
