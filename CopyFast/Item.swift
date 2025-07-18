//
//  Item.swift
//  CopyFast
//
//  Created by Yeuda Borodyanski on 13/07/2025.
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
