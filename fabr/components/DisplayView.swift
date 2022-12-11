//
//  DisplayView.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 27/07/21.
//

import UIKit


@IBDesignable
class DisplayView: UIView {
    let segments = [
        DisplayPart(), //a - 0
        DisplayPart(), //b - 1
        DisplayPart(), //c - 2
        DisplayPart(), //d - 3
        DisplayPart(), //e - 4
        DisplayPart(), //f - 5
        DisplayPart(), //g - 6
    ]
    
    var onReset: ((Bool) -> Void)?
    var blinking = false
    
    @IBInspectable
    var big: Bool = false
    
    @IBInspectable
    var maxValue: Int = 9 { didSet { updateView() } }
    
    @IBInspectable
    var minValue: Int = 0 { didSet { updateView() } }
    
    @IBInspectable
    var value: Int = 0 { didSet { updateView() } }
    
    var getMinValue: Int { get { max(0, minValue) } }
    var getMaxValue: Int { get { min(9, maxValue) } }
    
    var getValue: Int { get { min(getMaxValue, max(getMinValue, value)) } }

    func setAllSegments(_ state: Bool = true) {
        for seg in segments {
            seg.active = state
        }
    }
    
    func setSegments(_ indexes: [Int], _ state: Bool = true) {
        for i in indexes {
            segments[i].active = state
        }
    }
    
    func updateView() {
        if blinking { return }
//        print("UPDATE VIEW TO \(getValue)")
        switch getValue {
        case 0:
            setAllSegments()
            setSegments([6], false)
        case 1:
            setAllSegments(false)
            setSegments([1, 2])
        case 2:
            setAllSegments()
            setSegments([2, 5], false)
        case 3:
            setAllSegments()
            setSegments([4, 5], false)
        case 4:
            setAllSegments()
            setSegments([0, 3, 4], false)
        case 5:
            setAllSegments()
            setSegments([1, 4], false)
        case 6:
            setAllSegments()
            setSegments([1], false)
        case 7:
            setAllSegments(false)
            setSegments([0, 1, 2])
        case 8:
            setAllSegments()
        case 9:
            setAllSegments()
            setSegments([4], false)
        default:
            setAllSegments(false)
        }
    }
    
    func blink(_ times: Int = 1) {
        blinking = true
        if times > 0 {
            self.setAllSegments(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.setAllSegments()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.setAllSegments(false)
                    if times <= 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            self.blinking = false
                            self.updateView()
                        }
                    } else {
                        self.blink(times - 1)
                    }
                }
            }
        }
    }
    
    func reset(_ goToMinValue: Bool = true, doFireCallback: Bool = false) {
        if goToMinValue { value = getMinValue } else { value = getMaxValue }
        if doFireCallback { onReset?(goToMinValue) }
    }
    
    func add(_ n: Int = 1, delay: Double = 0.1) {
        if n <= 0 { return }
        next()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.add(n - 1)
        }
    }
    
    func subtract(_ n: Int = 1, delay: Double = 0.1) {
        if n <= 0 { return }
        previous()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.subtract(n - 1)
        }
    }
    
    func next() {
        if getValue == getMaxValue {
            value = getMinValue
            onReset?(true)
        } else {
            value += 1
        }
        
    }
    
    func previous() {
        if getValue == getMinValue {
            value = getMaxValue
            onReset?(false)
        } else {
            value -= 1
        }
    }
    
    func setup() {
        self.backgroundColor = .clear
        let longSide: CGFloat = big ? 30 : 20
        let smallSide: CGFloat = big ? 6 : 4
        
        for (index, segment) in segments.enumerated() {
            segment.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(segment)
            if [0, 3, 6].contains(index) {
                segment.heightAnchor.constraint(equalToConstant: smallSide).isActive = true
                segment.widthAnchor.constraint(equalToConstant: longSide).isActive = true
                segment.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
                
                if index == 0 {
                    segment.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                } else if index == 3 {
                    segment.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
                } else {
                    segment.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
                }
                
            } else {
                segment.heightAnchor.constraint(equalToConstant: longSide).isActive = true
                segment.widthAnchor.constraint(equalToConstant: smallSide).isActive = true
                
                if [1, 2].contains(index) {
                    segment.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
                } else {
                    segment.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
                }
                
                if [1, 5].contains(index) {
                    segment.topAnchor.constraint(equalTo: self.topAnchor, constant: smallSide * 3 / 4).isActive = true
                } else {
                    segment.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -smallSide * 3 / 4).isActive = true
                }
                
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setup()
    }
}
