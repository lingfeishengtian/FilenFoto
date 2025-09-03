//
//  PhotoHeroAnimationController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class PhotoHeroAnimationController: NSObject {
    let heroInteractiveTransition = InteractiveHeroAnimatedTransition(movableXAxis: true, isModal: true)
    let detailedInfoInteractiveTransition = InteractiveHeroAnimatedTransition(movableXAxis: false, isModal: false)
    
    func beginHeroInteractiveTransition(initiallyInteractive: Bool, from: PhotoHeroAnimatorDelegate, to: PhotoHeroAnimatorDelegate) {
        heroInteractiveTransition.wantsInteractiveStart = initiallyInteractive
        
        heroInteractiveTransition.from = from
        heroInteractiveTransition.to = to
    }
    
    func beginDetailedInfoInteractiveTransition(initiallyInteractive: Bool, from: PhotoHeroAnimatorDelegate, to: PhotoHeroAnimatorDelegate) {
        detailedInfoInteractiveTransition.wantsInteractiveStart = initiallyInteractive
        
        detailedInfoInteractiveTransition.from = from
        detailedInfoInteractiveTransition.to = to
    }
    
    func beginDismissingInteractiveTransition() {
        heroInteractiveTransition.wantsInteractiveStart = true
        detailedInfoInteractiveTransition.wantsInteractiveStart = true
    }
    
    func isAnimating() -> Bool {
        heroInteractiveTransition.isAnimating() || detailedInfoInteractiveTransition.isAnimating()
    }
}
