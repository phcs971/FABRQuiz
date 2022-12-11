//
//  Scoreboard.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 27/07/21.
//

import UIKit


class Scoreboard: UIView {
    
    var startDate = Date()
    
    @IBOutlet weak var scoreboardView: UIView!
    
    @IBOutlet weak var minutesDecimal: DisplayView!
    @IBOutlet weak var minutesUnidade: DisplayView!
    @IBOutlet weak var secondsDecimal: DisplayView!
    @IBOutlet weak var secondsUnidade: DisplayView!
    
    @IBOutlet weak var homeDecimal: DisplayView!
    @IBOutlet weak var homeUnidade: DisplayView!
    
    @IBOutlet weak var awayDecimal: DisplayView!
    @IBOutlet weak var awayUnidade: DisplayView!
    
    @IBOutlet weak var homeIndicator: UIImageView!
    @IBOutlet weak var awayIndicator: UIImageView!
    
    @IBOutlet weak var downDisplay: DisplayView!
    @IBOutlet weak var quarterDisplay: DisplayView!
    
    var currentTurn: Turn = .Home {
        didSet {
            onTurnChanged?(currentTurn)
            UIView.animate(withDuration: 0.1) {
                if self.currentTurn == .Home {
                    self.homeIndicator.tintColor = .displayRed
                    self.awayIndicator.tintColor = .displayGray
                } else {
                    self.homeIndicator.tintColor = .displayGray
                    self.awayIndicator.tintColor = .displayRed
                }
            }
            self.resetupTimer()
        }
    }
    
    var timerOn: Bool = false
    
    var onTimeIsUp: (() -> Void)?
    
    var onGameEnd: (() -> Void)?
    
    var onTurnChanged: ((Turn) -> Void)?
    
    var onClose: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("Scoreboard", owner: self, options: nil)
        scoreboardView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(scoreboardView)
        
        scoreboardView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        scoreboardView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scoreboardView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        scoreboardView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        scoreboardView.layer.shadowColor = UIColor.black.cgColor
        scoreboardView.layer.shadowOffset = CGSize(width: 0, height: 12)
        scoreboardView.layer.shadowRadius = 12
        scoreboardView.layer.shadowOpacity = 0.5
        
        setupTimer()
        setupScores()
        setupTurns()
    }
    
    private func setupTimer() {
        minutesDecimal.maxValue = 5
        minutesDecimal.minValue = 0
        minutesDecimal.value = 0
        
        minutesUnidade.maxValue = 9
        minutesUnidade.minValue = 0
        minutesUnidade.value = 1
     
        secondsDecimal.maxValue = 5
        secondsDecimal.minValue = 0
        secondsDecimal.value = 0
        
        secondsUnidade.maxValue = 9
        secondsUnidade.minValue = 0
        secondsUnidade.value = 0
        
        secondsUnidade.onReset = { isMinValue in
            if !isMinValue {
                self.secondsDecimal.previous()
            }
        }
        
        secondsDecimal.onReset = { isMinValue in
            if !isMinValue {
                self.minutesUnidade.previous()
            }
        }
        
        minutesUnidade.onReset = { isMinValue in
            if !isMinValue {
                print("TIME IS UP")
                self.onTimeIsUp?()
                self.resetTimer()
            }
        }
    }
    
    func startTimer(timeDivider: Double = 1) {
        if timerOn { return }
        resetupTimer()
        timerOn = true
        startDate = Date()
        timerRunning(timeDivider)
    }
    
    func pauseTimer() {
        timerOn = false
    }
    
    func resetTimer() {
        self.timerOn = false
        self.secondsUnidade.reset()
        self.secondsDecimal.reset()
        self.minutesUnidade.reset()
        self.minutesDecimal.reset()
    }
    
    func resetupTimer() {
        self.timerOn = false
        minutesDecimal.value = 0
        minutesUnidade.value = 1
        secondsDecimal.value = 0
        secondsUnidade.value = 0
    }

    func timerRunning(_ timeDivider: Double = 1) {
        if timerOn {
            DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / timeDivider)) {
//                print("\(self.minutesDecimal.getValue)\(self.minutesUnidade.getValue):\(self.secondsDecimal.getValue)\(self.secondsUnidade.getValue)")
                if self.timerOn {
//                    self.secondsUnidade.previous()
                    let timePassed = max(60 - self.startDate.distance(to: Date()) * timeDivider, 0.0)
                    let str = intToTimeString(timePassed)
                    if timePassed == 0.0 {
                        self.minutesUnidade.onReset?(false)
                    }
                    
                    var i = str.startIndex
                    self.minutesDecimal.value = str[i].wholeNumberValue ?? 0
                    i = str.index(after: i)
                    self.minutesUnidade.value = str[i].wholeNumberValue ?? 0
                    i = str.index(after: i)
                    i = str.index(after: i)
                    self.secondsDecimal.value = str[i].wholeNumberValue ?? 0
                    i = str.index(after: i)
                    self.secondsUnidade.value = str[i].wholeNumberValue ?? 0
                    
                    self.timerRunning(timeDivider)
                }
            }
        }
    }
    
    private func setupScores() {
        self.homeUnidade.onReset = { isMinValue in
            if isMinValue { self.homeDecimal.next() }
        }
        
        self.awayUnidade.onReset = { isMinValue in
            if isMinValue { self.awayDecimal.next() }
        }
    }
    
    func addScore(_ turn: Turn, _ score: Int) {
        if turn == .Home {
            homeUnidade.add(score)
        } else {
            awayUnidade.add(score)
        }
    }

    func setupTurns() {
        downDisplay.minValue = 1
        downDisplay.maxValue = 4
        downDisplay.value = 1
        
        downDisplay.onReset = { isMinValue in
            if isMinValue {
                self.currentTurn.toggle()
                if self.currentTurn == .Home {
                    self.quarterDisplay.next()
                }
            }
        }
        
        quarterDisplay.minValue = 1
        quarterDisplay.maxValue = 4
        quarterDisplay.value = 1
        
        quarterDisplay.onReset = { isMinValue in
            if isMinValue {
                print("GAME OVER")
                self.onGameEnd?()
            }
        }
    }
    
    @IBAction func close(_ sender: Any) {
        onClose?()
    }
    
    func blink() {
        self.minutesDecimal.blink()
        self.minutesUnidade.blink()
        self.secondsDecimal.blink()
        self.secondsUnidade.blink()
        self.homeDecimal.blink()
        self.homeUnidade.blink()
        self.awayDecimal.blink()
        self.awayUnidade.blink()
        self.downDisplay.blink()
        self.quarterDisplay.blink()
    }
}
