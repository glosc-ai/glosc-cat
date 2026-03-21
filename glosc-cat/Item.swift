//
//  Item.swift
//  glosc-cat
//
//  Created by XiaoM on 2026/3/21.
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
