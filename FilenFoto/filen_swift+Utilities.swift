//
//  Utils.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/3/25.
//

import Foundation
import SwiftUI

private let colorMap: [String: Color] = [
    "red": .red,
    "orange": .orange,
    "yellow": .yellow,
    "green": .green,
    "blue": .blue,
    "purple": .purple,
    "pink": .pink,
    "brown": .brown,
    "black": .black,
    "white": .white,
    "gray": .gray,
]

extension Directory {
    func swiftColor() -> Color? {
        guard let color = self.color else {
            return nil
        }
        
        return colorMap[color.lowercased()]
    }

}
