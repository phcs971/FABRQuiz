//
//  TiebreakerView.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 29/07/21.
//

import UIKit

class TiebreakerView: UIView {
    var homeResult: Int = 0
    var awayResult: Int = 0
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var home1Label: UILabel!
    @IBOutlet weak var home2Label: UILabel!
    @IBOutlet weak var home3Label: UILabel!
    @IBOutlet weak var home4Label: UILabel!
    
    @IBOutlet weak var away1Label: UILabel!
    @IBOutlet weak var away2Label: UILabel!
    @IBOutlet weak var away3Label: UILabel!
    @IBOutlet weak var away4Label: UILabel!
    
    @IBOutlet weak var homeResultLabel: UILabel!
    @IBOutlet weak var awayResultLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("TiebreakerView", owner: self, options: nil)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentView)

        contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    func setValues(_ game: GameModel) {
        home1Label.text = intToTimeString(game.rounds[0].homeTime)
        home2Label.text = intToTimeString(game.rounds[1].homeTime)
        home3Label.text = intToTimeString(game.rounds[2].homeTime)
        home4Label.text = intToTimeString(game.rounds[3].homeTime)
        
        away1Label.text = intToTimeString(game.rounds[0].awayTime)
        away2Label.text = intToTimeString(game.rounds[1].awayTime)
        away3Label.text = intToTimeString(game.rounds[2].awayTime)
        away4Label.text = intToTimeString(game.rounds[3].awayTime)
        
        homeResultLabel.text = "00:00"
        awayResultLabel.text = "00:00"
        
        (homeResult, awayResult) = game.getTimes()
    }
    
    func animateTexts() {
        UIView.animate(withDuration: 0.5, delay: 0) {
            self.home1Label.alpha = 1
            self.away1Label.alpha = 1
        }
        UIView.animate(withDuration: 0.5, delay: 0.25) {
            self.home2Label.alpha = 1
            self.away2Label.alpha = 1
        }
        UIView.animate(withDuration: 0.5, delay: 0.5) {
            self.home3Label.alpha = 1
            self.away3Label.alpha = 1
        }
        UIView.animate(withDuration: 0.5, delay: 0.75) {
            self.home4Label.alpha = 1
            self.away4Label.alpha = 1
        }
        UIView.animate(withDuration: 0.5, delay: 1) {
            self.homeResultLabel.alpha = 1
            self.awayResultLabel.alpha = 1
            self.animateResult()
        }
        
    }
    
    func animateResult() {
        self.homeResultLabel.animateTime(to: homeResult)
        self.awayResultLabel.animateTime(to: awayResult)
    }

}
