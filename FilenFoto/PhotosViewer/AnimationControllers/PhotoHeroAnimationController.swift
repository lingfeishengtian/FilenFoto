//
//  PhotoHeroAnimationController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class PhotoHeroAnimationController: NSObject {
    let heroInteractiveTransition = InteractiveHeroAnimatedTransition(movableXAxis: true)
    let detailedInfoInteractiveTransition = InteractiveHeroAnimatedTransition(movableXAxis: false)
    
    func beganTransition(initiallyInteractive: Bool) {
        heroInteractiveTransition.wantsInteractiveStart = initiallyInteractive
        detailedInfoInteractiveTransition.wantsInteractiveStart = initiallyInteractive
    }
    
    func isAnimating() -> Bool {
        heroInteractiveTransition.isAnimating() || detailedInfoInteractiveTransition.isAnimating()
    }
}
