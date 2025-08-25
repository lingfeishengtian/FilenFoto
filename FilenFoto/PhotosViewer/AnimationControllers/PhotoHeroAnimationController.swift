//
//  PhotoHeroAnimationController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class PhotoHeroAnimationController: NSObject {
    let heroAnimationTransition = HeroAnimatedTransition()
    let heroInteractiveTransition = InteractiveHeroAnimatedTransition()
    let detailedInfoTransition = DetailedInfoTransition()
    let detailedInfoInteractiveTransition = DetailedInfoInteractiveTransition()
    var isInteractive = false
}
