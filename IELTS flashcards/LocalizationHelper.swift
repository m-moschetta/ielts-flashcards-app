//
//  LocalizationHelper.swift
//  IELTS flashcards
//
//  Created by Mario Moschetta on 18/10/25.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

