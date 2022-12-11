//
//  GameViewController.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 26/07/21.
//

import UIKit
import GameKit

class GameViewController: UIViewController, GKMatchDelegate {
    
    //MARK: PROPERTIES
    var coveredSafeArea = false, finished = false, wo = false
    
    var gameMode: GameMode = .Offline
    
    var game: GameModel!
    
    var match: GKMatch?
    
    var currentAnswers: [AnswerModel]!
    
    var startTime: Date = Date()
    var lastInterval: Double = 60
    
    //MARK: GETTERS
    
    var quarter: Int { get { self.scoreboardView.quarterDisplay.getValue } }
    var down: Int { get { self.scoreboardView.downDisplay.getValue } }
    
    var cloud: CloudService { get { CloudService.shared } }
    
    var currentQuestion: QuestionModel { get { game.getQuestion(down, quarter) } }
    
    //MARK: OUTLETS
    
    @IBOutlet weak var tutorialView: UIView!
    
    @IBOutlet weak var waitingView: UIView!
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var waitingImage: UIImageView!
    
    @IBOutlet weak var quizBackground: UIView!
    @IBOutlet weak var quizLabel: UILabel!
    
    @IBOutlet weak var option1Button: CustomButton!
    @IBOutlet weak var option2Button: CustomButton!
    @IBOutlet weak var option3Button: CustomButton!
    @IBOutlet weak var option4Button: CustomButton!
    
    @IBOutlet weak var scoreboardView: Scoreboard!
    
    //MARK: CONTROLLER LIFECYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupGame()
        startTutorial()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        coverSaveArea()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("DID DISAPPEAR")
        self.match?.disconnect()
    }
    
    @objc func onDismiss() {
        self.match?.disconnect()
        self.dismiss(animated: true)
    }
    
    //MARK: SETUP

    func setupViews() {
        self.quizBackground.layer.cornerRadius = 32
        self.quizBackground.layer.shadowOpacity = 0.5
        self.quizBackground.layer.shadowRadius = 12
        self.quizBackground.layer.shadowColor = UIColor.black.cgColor
        self.quizBackground.layer.shadowOffset = .zero
        
        self.waitingView.layer.cornerRadius = 32
        self.waitingView.layer.shadowOpacity = 0.5
        self.waitingView.layer.shadowRadius = 12
        self.waitingView.layer.shadowColor = UIColor.black.cgColor
        self.waitingView.layer.shadowOffset = .zero
        
        self.tutorialView.layer.cornerRadius = 32
        self.tutorialView.layer.shadowOpacity = 0.5
        self.tutorialView.layer.shadowRadius = 12
        self.tutorialView.layer.shadowColor = UIColor.black.cgColor
        self.tutorialView.layer.shadowOffset = .zero
    }
    
    func coverSaveArea() {
        if coveredSafeArea { return }
        coveredSafeArea = true
        let topSafeArea = view.safeAreaInsets.top
        if topSafeArea > 0 {
            let top = UIView()
            top.backgroundColor = .scoreboard
            top.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(top)
            
            top.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            top.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            top.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            top.heightAnchor.constraint(equalToConstant: topSafeArea).isActive = true
        }
    }
    
    func setupMatch(_ gameMode: GameMode, with match: GKMatch? = nil) {
        self.match = match
        self.gameMode = gameMode
        if gameMode == .Online {
            let match = match!
            match.delegate = self
            var players = match.players.map( { $0.displayName })
            players.append(GKLocalPlayer.local.displayName)
            players.sort()
            let isFirst = players.first == GKLocalPlayer.local.displayName
            if isFirst {
                self.game = GameModel(home: .Local, away: .Human, mode: .Online)
            } else {
                self.game = GameModel(home: .Human, away: .Local, mode: .Online)
            }
        } else {
            self.game = GameModel()
        }
    }
    
    func setupGame() {
        self.scoreboardView.onClose = onDismiss
        
        self.scoreboardView.onTurnChanged = { self.game.turn = $0 }
        
        self.scoreboardView.onTimeIsUp = {
            if self.game.playerTurn {
                self.game.addTime(quarter: self.quarter, time: 60)
                
                self.sendData(MultiplayerData(command: "setTime", arguments: "60"))
                self.sendData(MultiplayerData(command: "endTurn"))
                self.scoreboardView.downDisplay.reset(true, doFireCallback: true)
                self.endTurn()
            }
        }
        self.scoreboardView.onGameEnd = { self.game.setState(.Finishing) }
        
        getQuestions()
    }
    
    func getQuestions() {
        for lvl in 1..<5 {
            let round = RoundModel(cloud.questions.filter{ $0.level == lvl }.randomElements(4))
            self.game.rounds.append(round)
        }
    }
    
    func startTutorial() {
        UIView.animate(withDuration: 0.5, delay: 1) {
            self.tutorialView.alpha = 1
        }
    }
    
    //MARK: GAME LIFECYCLE
    
    func startGame() {
        if self.game.ready {
            self.game.setState(.Playing)
            self.startRound(isFirstRound: true)
        } else if self.game.playerReady {
            UIView.animate(withDuration: 0.5) {
                self.quizBackground.alpha = 0
                self.tutorialView.alpha = 0
            } completion: { _ in
                self.waitingLabel.text = "ESPERANDO ADVERSÁRIO"
                UIView.animate(withDuration: 0.5, delay: 1) {
                    self.waitingView.alpha = 1
                }
            }
        }
    }
    
    func startRound(isFirstRound: Bool = false) {
        if !self.game.isState([.Playing, .Waiting]) { return }
        self.startTurn(isFirstRound: isFirstRound)
    }
    
    func startTurn(isFirstRound: Bool = false) {
        if isFirstRound { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.scoreboardView.blink() } }
        if self.game.playerTurn {
            UIView.animate(withDuration: 0.5) {
                self.tutorialView.alpha = 0
                self.waitingView.alpha = 0
            } completion: { _ in
                UIView.animate(withDuration: 0.5, delay: 1) {
                    self.quizBackground.alpha = 1
                    self.startTime = Date()
                    self.startQuestion()
                } completion: { _ in
                    self.scoreboardView.resetupTimer()
                    self.scoreboardView.startTimer()
                }
            }
        } else {
            self.waitForAdversary()
        }
    }
    
    func startQuestion() {
        if (game.playerTurn && game.isState(.Playing)) { updateQuestion() }
    }
    
    func endQuestion(_ selectedAnswer: Int) {
        if (game.playerTurn && game.isState(.Playing)) {
            let isCorrect = currentAnswers[selectedAnswer].correct
            if isCorrect { self.game.addCorrect(quarter: quarter) }
            
            cloud.updateQuestion(currentQuestion.id, wasCorrect: isCorrect)

            let isLastQuestion = self.down == 4
            if isLastQuestion {
                self.scoreboardView.pauseTimer()
                self.lastInterval = Date().timeIntervalSince(startTime)
                self.game.addTime(quarter: quarter, time: lastInterval)
                self.sendData(MultiplayerData(command: "setTime", arguments: String(lastInterval)))
            }

            self.animateButtons(selectedAnswer, isCorrect: isCorrect) { _ in
                self.nextDown()
                self.sendData(MultiplayerData(command: "nextDown", arguments: isCorrect ? "1" : "0"))
                if isLastQuestion {
                    self.endTurn()
                    self.sendData(MultiplayerData(command: "endTurn"))
                }
                else { self.startQuestion() }
            }
        }
    }
    
    func endTurn() {
//        if self.game.isState(.Finishing) { return }
        self.scoreboardView.downDisplay.reset()
        if game.turn == .Away {
            self.score(.Home)
            startTurn()
        } else {
            self.score(.Away)
            endRound()
        }
    }
    
    func endRound() {
        self.game.complete(quarter == 1 ? 4 : quarter - 1)
        if game.isState(.Finishing) {
            endGame()
        } else {
            startRound()
        }
    }
    
    func endGame() {
        if finished { return }
        finished = true
        
        self.scoreboardView.quarterDisplay.value = 4
        self.scoreboardView.downDisplay.value = 4
        self.scoreboardView.resetTimer()
        
        let resultView = UIView()
        resultView.translatesAutoresizingMaskIntoConstraints = false
        
        resultView.layer.cornerRadius = 32
        resultView.layer.shadowOpacity = 0.5
        resultView.layer.shadowRadius = 12
        resultView.layer.shadowColor = UIColor.black.cgColor
        resultView.layer.shadowOffset = .zero
        resultView.alpha = 0
        resultView.backgroundColor = .appGreen
        
        self.view.addSubview(resultView)
        
        resultView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 32).isActive = true
        resultView.topAnchor.constraint(equalTo: self.scoreboardView.bottomAnchor, constant: 32).isActive = true
        resultView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -32).isActive = true
        resultView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.bottomAnchor, constant: -32 - view.safeAreaInsets.bottom).isActive = true
        
        let resultLabel = UILabel()
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        
        var win = false
        let tie = self.wo ? false : game.getResult() == .Tie
        
        func setLabel() { resultLabel.text = win ? "VITÓRIA" : "DERROTA" }
        if wo {
            win = false
            resultLabel.text = "VITÓRIA"
        } else {
            switch game.getTieBreaker() {
            case .Tie:
                resultLabel.text = "EMPATE"
            case .HomeWin:
                if game.homePlayer == .Local { win = true }
                setLabel()
            case .AwayWin:
                if game.awayPlayer == .Local { win = true }
                setLabel()
            }
        }
        
        
        if !wo { GameService.shared.onGameEnd(win: win, gameMode: gameMode) }
        
        resultLabel.alpha = 0
        
        resultLabel.textColor = .yellow
        resultLabel.font = .systemFont(ofSize: 30, weight: .bold)
        resultLabel.textAlignment = .center
        
        resultView.addSubview(resultLabel)
        resultLabel.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 24).isActive = true
        resultLabel.topAnchor.constraint(equalTo: resultView.topAnchor, constant: 24).isActive = true
        resultLabel.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -24).isActive = true
        
        let scoreLabel = UILabel()
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scoreLabel.alpha = 0
        let (hScore, aScore) = self.game.getScore()
        scoreLabel.text = self.wo ? "W.O." : "\(hScore)x\(aScore)"
        scoreLabel.textAlignment = .center
        
        scoreLabel.textColor = .white
        scoreLabel.font = .systemFont(ofSize: 32, weight: .bold)
        
        resultView.addSubview(scoreLabel)
        scoreLabel.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 24).isActive = true
        scoreLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 4).isActive = true
        scoreLabel.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -24).isActive = true
        
        let returnButton = CustomButton()
        
        returnButton.translatesAutoresizingMaskIntoConstraints = false
        returnButton.alpha = 0
        
        returnButton.text = "CONTINUAR"
        returnButton.color = .appLightGreen
        returnButton.addTarget(self, action: #selector(self.onDismiss), for: .touchUpInside)
        
        resultView.addSubview(returnButton)
        
        returnButton.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 24).isActive = true
        returnButton.bottomAnchor.constraint(equalTo: resultView.bottomAnchor, constant: -24).isActive = true
        returnButton.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -24).isActive = true
        returnButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        let tiebreakerView = TiebreakerView()
        
        if tie {
            tiebreakerView.translatesAutoresizingMaskIntoConstraints = false
            tiebreakerView.setValues(game)
            tiebreakerView.alpha = 0
            
            resultView.addSubview(tiebreakerView)
            tiebreakerView.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 24).isActive = true
            tiebreakerView.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 24).isActive = true
            tiebreakerView.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -24).isActive = true
            tiebreakerView.heightAnchor.constraint(equalToConstant: 138).isActive = true
            returnButton.topAnchor.constraint(equalTo: tiebreakerView.bottomAnchor, constant: 24).isActive = true
            
        } else {
            returnButton.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 24).isActive = true
        }
        
        func showScoreAndResult(_ delay: TimeInterval = 0.5) {
            UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseInOut) {
                resultLabel.alpha = 1
                scoreLabel.alpha = 1
            } completion: { _ in
                UIView.animate(withDuration: 1) {
                    returnButton.alpha = 1
                }
            }
        }
        
        UIView.animate(withDuration: 0.5) {
            self.tutorialView.alpha = 0
            self.waitingView.alpha = 0
            self.quizBackground.alpha = 0
        } completion: {  _ in
            self.tutorialView.removeFromSuperview()
            self.waitingView.removeFromSuperview()
            self.quizBackground.removeFromSuperview()
            UIView.animate(withDuration: 0.5, delay: 1) {
                resultView.alpha = 1
            } completion: { _ in
                if tie {
                    UIView.animate(withDuration: 0.5) {
                        tiebreakerView.alpha = 1
                    } completion: { _ in
                        tiebreakerView.animateTexts()
                        showScoreAndResult(2)
                    }
                } else {
                    showScoreAndResult()

                }
            }
            
        }
    }
    
    //MARK: GAME FUNCTIONS
    
    func updateQuestion() {
        currentAnswers = currentQuestion.getAnswers
        quizLabel.text = currentQuestion.text
        option1Button.text = currentAnswers[0].text
        option2Button.text = currentAnswers[1].text
        option3Button.text = currentAnswers[2].text
        option4Button.text = currentAnswers[3].text
    }
    
    func nextDown() { self.scoreboardView.downDisplay.next() }
    
    func animateButtons(_ selectedAnswer: Int, isCorrect: Bool, completion: @escaping ((Bool) -> Void)) {
        let buttons = [option1Button, option2Button, option3Button, option4Button]
        let correctOption = currentAnswers.firstIndex(where: { $0.correct })!
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            if !isCorrect { buttons[selectedAnswer]?.backgroundColor = .displayRed }
            buttons[correctOption]?.backgroundColor = .appGreen
        } completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 0.25, options: .curveEaseOut, animations: { for b in buttons { b?.backgroundColor = .appLightGreen } }, completion: completion)
        }
    }
        
    func waitForAdversary() {
        let isOnline = gameMode == .Online
        UIView.animate(withDuration: 0.5) {
            self.quizBackground.alpha = 0
            self.tutorialView.alpha = 0
        } completion: { _ in
            self.waitingLabel.text = isOnline ? "AGUARDANDO SUA VEZ" : "SIMULANDO JOGO"
            UIView.animate(withDuration: 0.5, delay: 1) {
                self.waitingView.alpha = 1
            } completion: { _ in
                if isOnline { self.waitForHumanTurn() } else { self.simulateComputerTurn() }
            }
        }
    }
    
    func waitForHumanTurn() {
        self.scoreboardView.resetupTimer()
        self.scoreboardView.startTimer()
    }

    func simulateComputerTurn() {
        func simulateAnswer() { if (Bool.random()) { self.game.addCorrect(quarter: self.quarter) } }
        
        print("\nSimulating computer turn:")
        
        self.scoreboardView.resetupTimer()
        self.scoreboardView.startTimer(timeDivider: 30)
        simulateAnswer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.nextDown(); simulateAnswer() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.nextDown(); simulateAnswer() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.nextDown(); simulateAnswer() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let border = Double(Int.random(in: -8...12))
            let mult = Double.random(in: 0.1...1)
            
            let computerInterval = min(max(self.lastInterval + border * mult, 2.0 + mult), 58.0 + mult)
            self.game.addTime(quarter: self.quarter, time: computerInterval)
            
            print("Correct: \(self.game.rounds[self.quarter - 1].awayCorrect)")
            print("Points:  \(self.game.rounds[self.quarter - 1].awayPoints)")
            print("Time:    \(self.game.rounds[self.quarter - 1].awayTime)\n")
            self.nextDown()
            self.endTurn()
        }
    }
    
    func score(_ turn: Turn) {
        if turn == .Home {
            self.scoreboardView.addScore(.Home, self.game.rounds[quarter - 1].homePoints)
        } else {
            let q = quarter == 1 ? 3 : quarter - 2
            self.scoreboardView.addScore(.Away, self.game.rounds[q].awayPoints)
        }
    }
    
    //MARK: ACTIONS
    
    @IBAction func onReady(_ sender: Any) {
        self.game.setReady()
        startGame()
        self.sendData(MultiplayerData(command: "setReady"))
    }
    
    @IBAction func tapOption1(_ sender: Any) { endQuestion(0) }
    @IBAction func tapOption2(_ sender: Any) { endQuestion(1) }
    @IBAction func tapOption3(_ sender: Any) { endQuestion(2) }
    @IBAction func tapOption4(_ sender: Any) { endQuestion(3) }
    
    //MARK: MULTIPLAYER FUNCTIONS
    
    private func sendData(_ msg: MultiplayerData) {
        guard let match = match, gameMode == .Online else { return }

        do {
            guard let data = msg.encode() else { return }
            try match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            printError(error)
        }
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        do {
            print(String(data: data, encoding: .utf8)!)
            let model = try JSONDecoder().decode(MultiplayerData.self, from: data)
            
            switch model.command {
            case "nextDown":
                if (model.arguments == "1") { self.game.addCorrect(quarter: quarter) }
                self.nextDown()
            case "setTime":
                self.game.addTime(quarter: self.quarter, time: Double(model.arguments)!)
            case "endTurn":
                self.endTurn()
            case "setReady":
                self.game.setReady(.Human)
                self.startGame()
            default: break
            }
        } catch {
            printError(error)
        }
    }
    
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
        self.onCancel()
        return false
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        if state == .disconnected {
            self.onCancel()
        }
    }
    
    func onCancel() {
        DispatchQueue.main.async {
            self.wo = true
            self.game.setState(.Finishing)
            self.endGame()
        }
    }
    
    //MARK: STATUS BAR
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}

struct MultiplayerData: Codable {
    let command: String
    var arguments: String = ""
    
    func encode() -> Data? {
        return try? JSONEncoder().encode(self)
    }
        
    static func decode(data: Data) -> MultiplayerData? {
        return try? JSONDecoder().decode(MultiplayerData.self, from: data)
    }
}
