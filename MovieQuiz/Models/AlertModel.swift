//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Semen Kocherga on 14.03.2023.
//

import UIKit

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    var completion: ((UIAlertAction) -> Void)?
}
