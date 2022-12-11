//
//  DisplayPart.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 26/07/21.
//

import UIKit

@IBDesignable
class DisplayPart: UIView {
    
    var currentColor: UIColor { get { self.active ? UIColor.displayRed : UIColor.displayGray } }
    
    @IBInspectable var active: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        let path = UIBezierPath()

        if rect.height >= rect.width {
            path.move(to: CGPoint(x: rect.width / 2, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.width / 2))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - rect.width / 2))
            path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - rect.width / 2))
            path.addLine(to: CGPoint(x: 0, y: rect.width / 2))
        } else {
            path.move(to: CGPoint(x: 0, y: rect.height / 2))
            path.addLine(to: CGPoint(x: rect.height / 2, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - rect.height / 2, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            path.addLine(to: CGPoint(x: rect.width - rect.height / 2, y: 0))
            path.addLine(to: CGPoint(x: rect.height / 2, y: 0))
        }

        path.close()
        currentColor.set()
        path.fill()
    }
}
