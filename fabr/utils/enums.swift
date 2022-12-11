//
//  enums.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 29/07/21.
//

import Foundation


enum GameMode: Int, Codable {
    case Offline = 0
    case Online = 1
}

enum GameStatus: Int, Codable {
    case Starting = 0
    case Playing = 1
    case Waiting = 2
    case Finishing = 3
}

enum GameResult: Int, Codable {
    case HomeWin = 0
    case AwayWin = 1
    case Tie = 2
}

enum PlayerType: Int, Codable {
    case Local = 0
    case Computer = 1
    case Human = 2
}

enum Turn: Int, Codable {
    case Home = 0
    case Away = 1
    
    mutating func toggle() { self = self == .Home ? .Away : .Home }
}
