//
//  Item.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
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
