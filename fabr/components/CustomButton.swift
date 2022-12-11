//
//  CustomButton.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 26/07/21.
//

import UIKit

@IBDesignable
class CustomButton: UIButton {
    
    @IBInspectable
    var color: UIColor? = .appLightGreen { didSet { backgroundColor = color } }
    
    @IBInspectable
    var text: String? { didSet { updateText() } }
    
    @IBInspectable
    var textColor: UIColor? = UIColor.black { didSet { updateText() } }
    
    @IBInspectable
    var hasShadow: Bool = true { didSet { setShadow() } }
    
    func updateText() {
        self.setTitle(text, for: .normal)
        self.setTitleColor(textColor, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        self.titleEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.textAlignment = .center
    }
    
    func setShadow() {
        self.layer.shadowOffset = hasShadow ? CGSize(width: -4, height: 4) : CGSize.zero
        self.layer.shadowOpacity = hasShadow ? 0.25 : 0
        self.layer.shadowRadius = 0
        self.layer.shadowColor = hasShadow ? UIColor.black.cgColor : nil
        
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }

    func setup() {
        self.layer.cornerRadius = 16
        self.setShadow()
        self.clipsToBounds = false
    }
    
}
