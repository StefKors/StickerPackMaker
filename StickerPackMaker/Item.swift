//
//  Item.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 12/11/2023.
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
