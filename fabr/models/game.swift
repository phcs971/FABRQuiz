//
//  game.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 29/07/21.
//

import Foundation

class GameModel: Equatable, Identifiable, Codable {
    static func == (lhs: GameModel, rhs: GameModel) -> Bool { lhs.id == rhs.id }
    
    var id: String = UUID().uuidString
    var rounds = [RoundModel]()
    
    var homeReady = false
    var awayReady = false
    
    var ready: Bool { get { homeReady && awayReady } }
    
    var state = GameStatus.Starting
    
    var homePlayer: PlayerType
    var awayPlayer: PlayerType
    
    let gameMode: GameMode
    
    var turn = Turn.Home { didSet { setState(playerTurn ? .Playing : .Waiting) } }
    
    var playerTurn: Bool { get { (turn == .Home ? homePlayer : awayPlayer) == .Local } }
    
    var playerReady: Bool { get { (homePlayer == .Local && homeReady) || (awayPlayer == .Local && awayReady) } }
    
    init(home: PlayerType = .Local, away: PlayerType = .Computer, mode: GameMode = .Offline) {
        self.homePlayer = home
        self.awayPlayer = away
        self.gameMode = mode
        if mode == .Offline { awayReady = true }
    }
    
    func setReady(_ player: PlayerType = .Local) {
        if homePlayer == player  {
            homeReady = true
        } else if awayPlayer == player {
            awayReady = true
        }
    }
    
    func setState(_ state: GameStatus) { if self.state != .Finishing { self.state = state } }
    
    func isState(_ state: GameStatus) -> Bool { self.state == state }
    func isState(_ states: [GameStatus]) -> Bool { states.contains(self.state) }
    
    func addCorrect(quarter: Int, turn: Turn? = nil) {
        if (turn ?? self.turn) == .Home {
            rounds[quarter - 1].homeCorrect += 1
        } else {
            rounds[quarter - 1].awayCorrect += 1
        }
    }
    
    func addTime(quarter: Int, time: Double, turn: Turn? = nil) {
        if (turn ?? self.turn) == .Home {
            rounds[quarter - 1].homeTime = time
        } else {
            rounds[quarter - 1].awayTime = time
        }
    }
    
    func getQuestion(_ down: Int, _ quarter: Int) -> QuestionModel { rounds[quarter - 1].questions[down - 1] }
    
    func complete(_ quarter: Int) {
        rounds[quarter - 1].roundComplete = true
    }
    
    func getScore() -> (Int, Int) {
        var h = 0, a = 0
        for r in rounds {
            if !r.roundComplete { continue }
            h += r.homePoints
            a += r.awayPoints
        }
        return (h, a)
    }
    
    func getResult() -> GameResult {
        let (h, a) = getScore()
        if h > a {
            return .HomeWin
        } else if h < a {
            return .AwayWin
        } else {
            return .Tie
        }
    }
    
    func getTimes() -> (Int, Int) {
        var hTime = 0, aTime = 0
        for r in rounds {
            if !r.roundComplete { continue }
            hTime += Int(r.homeTime)
            aTime += Int(r.awayTime)
        }
        return (hTime, aTime)
    }
    
    func getTieBreaker() -> GameResult {
        let normalResult = getResult()
        if normalResult == .Tie {
            let (hTime, aTime) = getTimes()
            if hTime > aTime {
                return .AwayWin
            } else if hTime < aTime {
                return .HomeWin
            } else {
                return .Tie
            }
        } else {
            return normalResult
        }
    }
    
    func encode() -> Data? {
        return try? JSONEncoder().encode(self)
    }
        
    static func decode(data: Data) -> GameModel? {
        return try? JSONDecoder().decode(GameModel.self, from: data)
    }
}

class RoundModel: Equatable, Identifiable, Codable {
    static func == (lhs: RoundModel, rhs: RoundModel) -> Bool { lhs.id == rhs.id }
    
    
    var id: String = UUID().uuidString
    
    var questions: [QuestionModel] = []
    
    var homeCorrect: Int = 0 { didSet { setPoints(.Home) } }
    var awayCorrect: Int = 0 { didSet { setPoints(.Away) } }
    
    var homeTime: Double = 0
    var awayTime: Double = 0
    
    var homePoints: Int = 0
    var awayPoints: Int = 0
    
    var roundComplete = false
    
    init(_ questions: [QuestionModel]) {
        self.questions = questions
    }
    
    private func setPoints(_ turn: Turn) {
        let pointArray = [0, 3, 6, 7, 8]
//        let pointArray = [0, 0, 0, 0, 0]
        if turn == .Home {
            homePoints = pointArray[homeCorrect]
        } else {
            awayPoints = pointArray[awayCorrect]
        }
    }
}
