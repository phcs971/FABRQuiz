//
//  HomeViewController.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 26/07/21.
//

import UIKit
import GameKit

class HomeViewController: UIViewController, GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKLocalPlayerListener {
    var match: GKMatch?
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        printError(error)
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            viewController.dismiss(animated: true)
            self.match = match
            self.performSegue(withIdentifier: "startGame", sender: GameMode.Online)
        }
    }
    
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        let viewController = GKMatchmakerViewController(invite: invite)
        viewController?.matchmakerDelegate = self
        let rootViewController = UIApplication.shared.windows.first!.rootViewController
        rootViewController?.present(viewController!, animated: true, completion: nil)
    }
    
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    var games: GameService { get { GameService.shared } }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateUser()
    }
    
    func authenticateUser() {
        GKLocalPlayer.local.authenticateHandler = { vc, error in
            
            if let error = error {
                return printError(error)
            } else if let vc = vc {
                return self.present(vc, animated: true)
            }
            
            GKLocalPlayer.local.register(self)
        }
    }
    
    @IBAction func openLeaderboard(_ sender: Any) {
        let vc = games.getLeaderboard()
        vc.gameCenterDelegate = self
        self.present(vc, animated: true)
    }
    
    @IBAction func openAchievements(_ sender: Any) {
        let vc = games.getAchievements()
        vc.gameCenterDelegate = self
        self.present(vc, animated: true)
    }

    @IBAction func playComputer(_ sender: Any) {
        performSegue(withIdentifier: "startGame", sender: GameMode.Offline)
    }
    
    @IBAction func playOnline(_ sender: Any) {
        if let vc = games.getMatchRequest() {
            vc.matchmakerDelegate = self
            self.present(vc, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? GameViewController {
            if let gameMode = sender as? GameMode {
                vc.gameMode = gameMode
                if gameMode == .Online {
                    vc.setupMatch(.Online, with: self.match!)
                } else {
                    vc.setupMatch(.Offline)
                }
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
