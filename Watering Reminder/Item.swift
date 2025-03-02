//
//  Item.swift
//  Watering Reminder
//
//  Created by Sorour Eskandari on 01.01.25.
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
