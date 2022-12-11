//
//  clou.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 30/07/21.
//

import Foundation
import CloudKit

private class QuestionRecord {
    private init() { }
    
    static let recordType = "Question"
    static let level = "level"
    static let text = "text"
    static let numberOfAppearences = "numberOfAppearences"
    static let numberOfCorrect = "numberOfCorrect"
    static let correctAnswer = "correctAnswer"
    static func wrongAnswer(_ i: Int) -> String { "wrongAnswer\(i)" }
}

class CloudService {
    
    var busy = false
    
//    private init() { saveQuestions() }
    private init() { }
    
    static let shared = CloudService()
    
    private let database = CKContainer.default().publicCloudDatabase
    private let privateDatabase = CKContainer.default().privateCloudDatabase
    
    var questions: [QuestionModel] = []
    
    
    // TO CHANGE TO PRODUCTION -> fabr.entitlements -> com.apple.developer.icloud-container-environment = Production
    func saveQuestions() {
        for q in questionsList {
            let record = CKRecord(recordType: QuestionRecord.recordType, recordID: CKRecord.ID(recordName: q.id))
            record.setValue(q.level, forKey: QuestionRecord.level)
            record.setValue(q.numberOfAppearences, forKey: QuestionRecord.numberOfAppearences)
            record.setValue(q.text, forKey: QuestionRecord.text)
            record.setValue(q.numberOfCorrect, forKey: QuestionRecord.numberOfCorrect)
            record.setValue(q.correctAnswer.text, forKey: QuestionRecord.correctAnswer)
            for (index, ans) in q.wrongAnswers.enumerated() {
                record.setValue(ans.text, forKey: QuestionRecord.wrongAnswer(index + 1))
            }
            self.database.save(record) { record, error in if let error = error { printError(error) } }
        }
    }
    
    func updateQuestion(_ questionId: String, wasCorrect: Bool) {
        self.database.fetch(withRecordID: CKRecord.ID(recordName: questionId)) { record, error in
            guard let record = record, error == nil else { return printError(error) }
            record.setValue((record[QuestionRecord.numberOfAppearences] as? Int ?? 0) + 1, forKey: QuestionRecord.numberOfAppearences)
            if wasCorrect {
                record.setValue((record[QuestionRecord.numberOfCorrect] as? Int ?? 0) + 1, forKey: QuestionRecord.numberOfCorrect)
            }

            let index = self.questions.firstIndex(where: { $0.id == questionId })!
            self.questions[index] = self.recordToQuestion(record)
            
            self.database.save(record) { record, error in if let error = error { printError(error) } }
            
        }
    }
    
    func fetchQuestions() {
        busy = true
        let query = CKQuery(recordType: QuestionRecord.recordType, predicate: NSPredicate(value: true))
        self.database.perform(query, inZoneWith: nil) { records, error in
            guard let records = records, error == nil else {
                self.questions = questionsList
                self.busy = false
                return printError(error)
            }
            self.questions = records.compactMap(self.recordToQuestion)
            self.busy = false
        }
    }
    
    func recordToQuestion(_ record: CKRecord) -> QuestionModel {
        var answers = [AnswerModel(text: record[QuestionRecord.correctAnswer] as! String, correct: true)]
        for i in 1...3 {
            answers.append(AnswerModel(text: record[QuestionRecord.wrongAnswer(i)] as! String))
        }
        let q = QuestionModel(
            id: record.recordID.recordName,
            text: record[QuestionRecord.text] as! String,
            level: record[QuestionRecord.level] as! Int,
            answers: answers,
            numberOfAppearences: record[QuestionRecord.numberOfAppearences] as! Int,
            numberOfCorrect: record[QuestionRecord.numberOfCorrect] as! Int
        )
        return q
    }
    
    func fetchUser(completion: (() -> Void)? = nil) {
        print("FETCH")
        self.privateDatabase.fetch(withRecordID: CKRecord.ID(recordName: "playerStats")) { record, error in
            guard let record = record, error == nil else {
                if let error = error as? CKError, error.code == .unknownItem { return self.createUser(completion: completion) }
                return printError(error)
            }
            GameService.shared.updatePlayerStats(
                off: record["gamesPlayedOffline"] as? Int ?? 0,
                offWin: record["gamesWonOffline"] as? Int ?? 0,
                on: record["gamesPlayedOnline"] as? Int ?? 0,
                onWin: record["gamesWonOnline"] as? Int ?? 0
            )
            completion?()
        }
    }
    
    func updateUser() {
        print("UPDATE")
        self.privateDatabase.fetch(withRecordID: CKRecord.ID(recordName: "playerStats")) { record, error in
            guard let record = record, error == nil else {
                if let error = error as? CKError, error.code == .unknownItem { return self.createUser() }
                return printError(error)
            }
            let g = GameService.shared
            record.setValuesForKeys([
                "gamesPlayedOffline": g.gamesPlayedOffline,
                "gamesWonOffline": g.gamesWonOffline,
                "gamesPlayedOnline": g.gamesPlayedOnline,
                "gamesWonOnline": g.gamesWonOnline,
            ])
            self.privateDatabase.save(record) { record, error in if let error = error { printError(error) } }
        }
    }
    
    func createUser(completion: (() -> Void)? = nil) {
        print("CREATE USER")
        let record = CKRecord(recordType: "GameStats", recordID: CKRecord.ID(recordName: "playerStats"))
        let g = GameService.shared
        record.setValuesForKeys([
            "gamesPlayedOffline": g.gamesPlayedOffline,
            "gamesWonOffline": g.gamesWonOffline,
            "gamesPlayedOnline": g.gamesPlayedOnline,
            "gamesWonOnline": g.gamesWonOnline,
        ])
        self.privateDatabase.save(record) { record, error in
            if let error = error { return printError(error) }
            completion?()
        }
    }
}

private let questionsList: [QuestionModel] = [
    QuestionModel(
        text: "Qual dessas posições não é uma posição de ataque?",
        level: 1,
        answers: [
            AnswerModel(text: "Nose Tackle", correct: true),
            AnswerModel(text: "Guard"),
            AnswerModel(text: "Quarterback"),
            AnswerModel(text: "Tight End")
        ]
    ),
    QuestionModel(
        text: "Qual o comprimento do campo de futebol americano?",
        level: 1,
        answers: [
            AnswerModel(text: "120 jardas", correct: true),
            AnswerModel(text: "110 jardas"),
            AnswerModel(text: "100 jardas"),
            AnswerModel(text: "100 metros")
        ]
    ),
    QuestionModel(
        text: "Qual o nome da área onde os jogadores pontuam? (Em inglês)",
        level: 1,
        answers: [
            AnswerModel(text: "End Zone", correct: true),
            AnswerModel(text: "Scoring Zone"),
            AnswerModel(text: "Goal Box"),
            AnswerModel(text: "Score Box")
        ]
    ),
    QuestionModel(
        text: "Qual o nome da linha da bola no começo da jogada?",
        level: 1,
        answers: [
            AnswerModel(text: "Linha de Scrimmage", correct: true),
            AnswerModel(text: "Linha do First Down"),
            AnswerModel(text: "Linha de Start"),
            AnswerModel(text: "Linha da Bola")
        ]
    ),
    QuestionModel(
        text: "O que acontece quando um jogador derruba o quarterback atrás da linha de scrimmage?",
        level: 1,
        answers: [
            AnswerModel(text: "Sack", correct: true),
            AnswerModel(text: "Nada"),
            AnswerModel(text: "Falta"),
            AnswerModel(text: "Safety")
        ]
    ),
    QuestionModel(
        text: "Quantos jogadores entram em campo no time de defesa?",
        level: 1,
        answers: [
            AnswerModel(text: "11", correct: true),
            AnswerModel(text: "9"),
            AnswerModel(text: "7"),
            AnswerModel(text: "5")
        ]
    ),
    
    QuestionModel(
        text: "Qual desses não é considerado um dos times do futebol americano?",
        level: 1,
        answers: [
            AnswerModel(text: "Time de Corrida", correct: true),
            AnswerModel(text: "Time de Ataque"),
            AnswerModel(text: "Time de Defesa"),
            AnswerModel(text: "Time de Especialista")
        ]
    ),
    QuestionModel(
        text: "Quantas tentativas um time tem para conseguir um First Down?",
        level: 1,
        answers: [
            AnswerModel(text: "4", correct: true),
            AnswerModel(text: "3"),
            AnswerModel(text: "6"),
            AnswerModel(text: "5")
        ]
    ),
    QuestionModel(
        text: "Como é o nome da falta que ocorre quando um jogador do ataque se move antes do início da jogada?",
        level: 2,
        answers: [
            AnswerModel(text: "False Start", correct: true),
            AnswerModel(text: "Delay of Game"),
            AnswerModel(text: "Early Movement"),
            AnswerModel(text: "Offensive Boundary")
        ]
    ),
    QuestionModel(
        text: "Qual posição ofensiva é considerada a cabeça do ataque?",
        level: 2,
        answers: [
            AnswerModel(text: "Quarterback", correct: true),
            AnswerModel(text: "Wide Reciever"),
            AnswerModel(text: "Linebacker"),
            AnswerModel(text: "Running Back")
        ]
    ),
    QuestionModel(
        text: "Qual posição é normalmente considerada o capitão e líder da defesa?",
        level: 2,
        answers: [
            AnswerModel(text: "Linebacker", correct: true),
            AnswerModel(text: "Defensive Line"),
            AnswerModel(text: "Cornerback"),
            AnswerModel(text: "Safety")
        ]
    ),
    QuestionModel(
        text: "O que acontece quando, após os 4 quartos, o jogo está empadatado?",
        level: 2,
        answers: [
            AnswerModel(text: "Overtime", correct: true),
            AnswerModel(text: "Penalty"),
            AnswerModel(text: "Acaba empatado"),
            AnswerModel(text: "Cara ou coroa")
        ]
    ),
    QuestionModel(
        text: "Quantos pontos vale um touchdown?",
        level: 2,
        answers: [
            AnswerModel(text: "6", correct: true),
            AnswerModel(text: "7"),
            AnswerModel(text: "8"),
            AnswerModel(text: "3")
        ]
    ),
    QuestionModel(
        text: "O que acontece quando 5 ou mais jogadores atacam o quarterback?",
        level: 2,
        answers: [
            AnswerModel(text: "Blitz", correct: true),
            AnswerModel(text: "Spy"),
            AnswerModel(text: "Cover Zero"),
            AnswerModel(text: "Press Coverage")
        ]
    ),
    QuestionModel(
        text: "Qual posição é responsável por fazer o snap e começar a jogada?",
        level: 2,
        answers: [
            AnswerModel(text: "Center", correct: true),
            AnswerModel(text: "Guard"),
            AnswerModel(text: "Tackle"),
            AnswerModel(text: "Quarterback")
        ]
    ),
    QuestionModel(
        text: "Quantos pontos vale um safety?",
        level: 2,
        answers: [
            AnswerModel(text: "2", correct: true),
            AnswerModel(text: "6"),
            AnswerModel(text: "3"),
            AnswerModel(text: "1")
        ]
    ),
    QuestionModel(
        text: "Qual a punição para a falta Holding?",
        level: 3,
        answers: [
            AnswerModel(text: "10 jardas", correct: true),
            AnswerModel(text: "15 jardas"),
            AnswerModel(text: "5 jardas"),
            AnswerModel(text: "25 jardas")
        ]
    ),
    QuestionModel(
        text: "O quarterback faz um passe para um recebedor que está parado atrás dele. O que acontece se a bola cair no chão?",
        level: 3,
        answers: [
            AnswerModel(text: "Bola viva", correct: true),
            AnswerModel(text: "A jogada acaba"),
            AnswerModel(text: "Falta"),
            AnswerModel(text: "Mudança de posse")
        ]
    ),
    QuestionModel(
        text: "Como se chama as jogadas onde o quarterback escolhe se irá passar ou entregar a bola para corrida?",
        level: 3,
        answers: [
            AnswerModel(text: "RPO", correct: true),
            AnswerModel(text: "Zone Read"),
            AnswerModel(text: "Trap"),
            AnswerModel(text: "Option")
        ]
    ),
    QuestionModel(
        text: "Qual o nome da formação defensiva que conta com 3 DLs, 2 LBs e 6 DBs?",
        level: 3,
        answers: [
            AnswerModel(text: "Dime", correct: true),
            AnswerModel(text: "Nickel"),
            AnswerModel(text: "3-2"),
            AnswerModel(text: "2-6")
        ]
    ),
    QuestionModel(
        text: "O ataque entrou em campo com 1 RB, 0 TE e 3 WRs. Qual o personnel?",
        level: 3,
        answers: [
            AnswerModel(text: "10", correct: true),
            AnswerModel(text: "13"),
            AnswerModel(text: "31"),
            AnswerModel(text: "30")
        ]
    ),
    QuestionModel(
        text: "Qual a pontuação mínima que um time pode fazer em um jogo caso não acabe a partida com 0 pontos?",
        level: 3,
        answers: [
            AnswerModel(text: "1", correct: true),
            AnswerModel(text: "2"),
            AnswerModel(text: "3"),
            AnswerModel(text: "4")
        ]
    ),
    QuestionModel(
        text: "Um jogador está alinhado para receber um chute e retorná-lo, caso ele acene antes da bola chegar em sua mão, o que acontece?",
        level: 3,
        answers: [
            AnswerModel(text: "Fair Catch", correct: true),
            AnswerModel(text: "Falta por Provocação"),
            AnswerModel(text: "Nada"),
            AnswerModel(text: "Tempo Técnico")
        ]
    ),
    QuestionModel(
        text: "Qual o nome da rota onde o jogador corre 3-5 jardas para frente e corta em 45˚ pro meio do campo?",
        level: 3,
        answers: [
            AnswerModel(text: "Slant", correct: true),
            AnswerModel(text: "Cut"),
            AnswerModel(text: "Dig"),
            AnswerModel(text: "Fade")
        ]
    ),
    QuestionModel(
        text: "Que dia é comemorado o Futebol Americano no Brasil?",
        level: 4,
        answers: [
            AnswerModel(text: "25/10", correct: true),
            AnswerModel(text: "25/08"),
            AnswerModel(text: "05/09"),
            AnswerModel(text: "12/10")
        ]
    ),
    QuestionModel(
        text: "Qual o nome do primeiro jogador brasileiro a chegar na NFL?",
        level: 4,
        answers: [
            AnswerModel(text: "Cairo Santos", correct: true),
            AnswerModel(text: "Durval Queiroz"),
            AnswerModel(text: "Rodrigo Blakenship"),
            AnswerModel(text: "Breno Giacomini")
        ]
    ),
    QuestionModel(
        text: "Qual foi a primeira competição de Futebol Americano no Brasil?",
        level: 4,
        answers: [
            AnswerModel(text: "Carioca Bowl", correct: true),
            AnswerModel(text: "Paraná Bowl"),
            AnswerModel(text: "LBFA"),
            AnswerModel(text: "Torneio Touchdown")
        ]
    ),
    QuestionModel(
        text: "Onde foi o primeiro jogo de Futebol Americano Full Pads no Brasil?",
        level: 4,
        answers: [
            AnswerModel(text: "Curitiba", correct: true),
            AnswerModel(text: "Rio de Janeiro"),
            AnswerModel(text: "São Paulo"),
            AnswerModel(text: "Belo Horizonte")
        ]
    ),
    QuestionModel(
        text: "Qual seleção o Brasil derrotou na Copa do Mundo de Futebol Americano de 2015?",
        level: 4,
        answers: [
            AnswerModel(text: "Coreia do Sul", correct: true),
            AnswerModel(text: "França"),
            AnswerModel(text: "Austrália"),
            AnswerModel(text: "Estado Unidos")
        ]
    ),
    QuestionModel(
        text: "Com quantos times contou a competição BFA Feminino de 2019?",
        level: 4,
        answers: [
            AnswerModel(text: "8", correct: true),
            AnswerModel(text: "6"),
            AnswerModel(text: "4"),
            AnswerModel(text: "2")
        ]
    ),
    QuestionModel(
        text: "Qual desses nunca foi um campeonato nacional de Futebol Americano?",
        level: 4,
        answers: [
            AnswerModel(text: "Pick Six Cup", correct: true),
            AnswerModel(text: "BFA"),
            AnswerModel(text: "LNFA"),
            AnswerModel(text: "Torneio Touchdown")
        ]
    ),
    QuestionModel(
        text: "Qual é o animal da Seleção Brasileira de Futebol Americano?",
        level: 4,
        answers: [
            AnswerModel(text: "Onça", correct: true),
            AnswerModel(text: "Mico Leão Dourado"),
            AnswerModel(text: "Arara Azul"),
            AnswerModel(text: "Tamanduá")
        ]
    ),
]
