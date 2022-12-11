//
//  games.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 30/07/21.
//

import Foundation
import GameKit

struct Achievement {
    var id: String
    var gameMode: GameMode
    var goal: Int
    
    init(_ goal: Int, _ gameMode: GameMode) {
        self.goal = goal
        self.gameMode = gameMode
        self.id = "win_\(goal)_\(gameMode == .Online ? "online" : "pc")"
    }
    
    func getPercentage(_ value: Int) -> Double { min(100, 100 * Double(value) / Double(goal)) }
    
    func isComplete(_ value: Int) -> Bool { value >= goal }
}

class GameService {
    private init() { }
    
    private let achievements = [
        Achievement(1, .Online),
        Achievement(5, .Online),
        Achievement(10, .Online),
        Achievement(50, .Online),
        Achievement(100, .Online),
        Achievement(500, .Online),
        Achievement(1000, .Online),
        Achievement(1, .Offline),
        Achievement(5, .Offline),
        Achievement(10, .Offline),
        Achievement(50, .Offline),
        Achievement(100, .Offline),
        Achievement(500, .Offline),
        Achievement(1000, .Offline),
    ]
    
    var gamesWonOnline: Int = 0
    var gamesPlayedOnline: Int = 0
    var gamesWonOffline: Int = 0
    var gamesPlayedOffline: Int = 0
    
    static let shared = GameService()
    
    func getMatchRequest() -> GKMatchmakerViewController? {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.defaultNumberOfPlayers = 2
        return GKMatchmakerViewController(matchRequest: request)
    }
    
    func getLeaderboard() -> GKGameCenterViewController { GKGameCenterViewController(state: .leaderboards) }
    
    func getAchievements() -> GKGameCenterViewController { GKGameCenterViewController(state: .achievements) }
    
    func updateAchievemnts(_ gameMode: GameMode) {
        let value = gameMode == .Offline ? self.gamesWonOffline : self.gamesWonOnline
        var ids = self.achievements.filter{ $0.gameMode == gameMode }.compactMap{ $0.id }
        var toReport = [GKAchievement]()
        GKAchievement.loadAchievements { gkAchievements, error in
            guard let gkAchievements = gkAchievements, error == nil else { return printError(error) }
            for gkAchievement in gkAchievements {
                let id = gkAchievement.identifier
                if ids.contains(id), let achievement = self.achievements.first(where: { $0.id == id }) {
                    ids.removeAll { $0 == id }
                    gkAchievement.percentComplete = achievement.getPercentage(value)
                    toReport.append(gkAchievement)
                }
            }
            for id in ids {
                if let achievement = self.achievements.first(where: { $0.id == id }) {
                    let gkA = GKAchievement(identifier: id)
                    gkA.percentComplete = achievement.getPercentage(value)
                    toReport.append(gkA)
                }
            }
            GKAchievement.report(toReport) { error in printError(error) }
        }
    }
    
    func onGameEnd(win: Bool, gameMode: GameMode) {
        CloudService.shared.fetchUser() {
            if gameMode == .Offline {
                self.gamesPlayedOffline += 1
                if win {
                    self.gamesWonOffline += 1
                    GKLeaderboard.submitScore(
                        self.gamesWonOffline,
                        context: 0,
                        player: GKLocalPlayer.local,
                        leaderboardIDs: ["fabr_games_won_pc"],
                        completionHandler: printError
                    )
                    
                    self.updateAchievemnts(.Offline)

                }
            } else {
                self.gamesPlayedOnline += 1
                if win {
                    self.gamesWonOnline += 1
                    GKLeaderboard.submitScore(
                        self.gamesWonOffline,
                        context: 0,
                        player: GKLocalPlayer.local,
                        leaderboardIDs: ["fabr_games_won_online"],
                        completionHandler: printError
                    )
                    
                    self.updateAchievemnts(.Online)
                }
            }
            CloudService.shared.updateUser()
        }
    }
    
    func updatePlayerStats(off: Int, offWin: Int, on: Int, onWin: Int) {
        self.gamesWonOnline = onWin
        self.gamesPlayedOnline = on
        self.gamesWonOffline = offWin
        self.gamesPlayedOffline = off
    }
}
