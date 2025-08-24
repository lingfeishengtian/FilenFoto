//
//  Types.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit
import os

fileprivate let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AnimationReferences")

struct AnimationReferences {
    var imageReference: UIImageView
    var frame: CGRect
    
    // Initialize wtih defaults values when something goes wrong
    init(size: CGSize) {
        logger.warning("AnimationReferences initialized with default values")
        
        imageReference = UIImageView(frame: CGRect(origin: .zero, size: size))
        frame = CGRect(origin: .zero, size: size)
    }
    
    init(imageReference: UIImageView, frame: CGRect) {
        self.imageReference = imageReference
        self.frame = frame
    }
}

enum Direction {
    case up
    case down
}

