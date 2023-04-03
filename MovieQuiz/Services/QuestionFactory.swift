//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Semen Kocherga on 12.03.2023.
//

import Foundation

final class QuestionFactory: QuestionFactoryProtocol{
    private var movies: [MostPopularMovie] = []
    private let moviesLoader: MoviesLoading
    private  var delegate: QuestionFactoryDelegate?
    
    private let moreOrLess = ["больше", "меньше"]
    private let scoreRange = Range(65...95)
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items // сохраняем фильм в нашу новую переменную
                    self.delegate?.didLoadDataFromServer() // сообщаем, что данные загрузились
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error) // сообщаем об ошибке нашему MovieQuizViewController
                }
            }
        }
    }
 
    func requestNextQuestion() {
        self.delegate?.changeButtonsStatus()
        self.delegate?.showLoadingIndicator()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
            
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didFailToLoadImage()
                }
            }
            
            let rating = Float(movie.rating) ?? 0
            
            guard let maybeMoreOrLess = self.moreOrLess.randomElement() else { return }
            guard let randomScore = self.scoreRange.randomElement() else { return }
            
            let correctAnswer: Bool
            
            let text = "Рейтинг этого фильма \(maybeMoreOrLess) чем \(Float(randomScore) / 10)?"
            if maybeMoreOrLess == "больше" {
                correctAnswer = rating > (Float(randomScore) / 10)
            } else {
                correctAnswer = rating < (Float(randomScore) / 10)
            }
            
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
}


