//
//  question.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 28/07/21.
//

import Foundation

struct QuestionModel: Identifiable, Codable, Equatable {
    static func == (lhs: QuestionModel, rhs: QuestionModel) -> Bool { lhs.id == rhs.id }
    
    var id: String = UUID().uuidString
    
    var text: String
//    var image: String?
    
    var level: Int = 1
    
    var answers: [AnswerModel]
    
    var numberOfAppearences: Int = 0
    var numberOfCorrect: Int = 0
    
    var getAnswers: [AnswerModel] { get { answers.shuffled() } }
    
    var correctAnswer: AnswerModel { get { answers.first { $0.correct }! } }
    
    var wrongAnswers: [AnswerModel] { get { answers.filter { !$0.correct } } }
    
    func getData() -> Data? {
        let enc = JSONEncoder()
        return try? enc.encode(self)
    }
    
    func toJson() -> [String: Any]? {
        if let data = getData() {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }
        return nil
    }
}

struct AnswerModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    
    var text: String
    var correct: Bool = false
}


