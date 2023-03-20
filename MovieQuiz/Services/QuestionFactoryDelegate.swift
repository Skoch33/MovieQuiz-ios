//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Semen Kocherga on 13.03.2023.
//

import Foundation

protocol QuestionFactoryDelegate: AnyObject {               
    func didReceiveNextQuestion(question: QuizQuestion?)
}
