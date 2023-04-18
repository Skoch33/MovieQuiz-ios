//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Semen Kocherga on 12.04.2023.
//

import UIKit

protocol MovieQuizViewControllerProtocol: AnyObject {
    
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel)
    
    func highlightImageBorder(isCorrectAnswer: Bool)
    
    func showLoadingIndicator()
    func hideLoadingIndicator()
    func resetImageBorder()
    func changeButtonsStatus()
    
    func showNetworkError(message: String)
    
}

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private let statisticService = StatisticServiceImplementation()
    private var currentQuestion: QuizQuestion?
    private var correctAnswers: Int = 0
    private var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewControllerProtocol?
    
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        proceedWithAnswer(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
        viewController?.hideLoadingIndicator()
    }
    
    private func proceedToNextQuestionOrResults() {
        if isLastQuestion() {
            viewController?.resetImageBorder()
            statisticService.store(correct: correctAnswers, total: self.questionsAmount)
            statisticService.gamesCount += 1
            let text = correctAnswers == self.questionsAmount ?
            "Поздравляем, Вы ответили на 10 из 10!" : """
                    Ваш результат: \(correctAnswers)/10
                    Количество сыгранных квизов: \(statisticService.gamesCount)
                    Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
                    Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
                    """
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Cыграть ещё раз")
            viewController?.show(quiz: viewModel)
        } else {
            viewController?.resetImageBorder()
            switchToNextQuestion() // увеличиваем индекс текущего вопроса на 1; таким образом мы сможем получить следующий вопрос
            viewController?.showLoadingIndicator()
            questionFactory?.requestNextQuestion() // показать следующий вопрос
        }
    }
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    private func proceedWithAnswer(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        viewController?.changeButtonsStatus()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in  // запускаем задачу через 1 секунду
            guard let self = self else { return }
            // код, который вы хотите вызвать через 1 секунду,
            self.proceedToNextQuestionOrResults()
            self.viewController?.changeButtonsStatus()
        }
    }
}
