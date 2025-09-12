//
//  Item.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/7/25.
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
