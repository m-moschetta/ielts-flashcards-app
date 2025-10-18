//
//  Item.swift
//  IELTS flashcards
//
//  Created by Mario Moschetta on 18/10/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
