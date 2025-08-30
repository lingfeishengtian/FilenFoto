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
    
    private weak var navigationController: UINavigationController?
    private let panGestureRecognizer = UIPanGestureRecognizer()
    
    // TODO: FIx remove navigationController
    init(navigationController: UINavigationController) {
        super.init()
        
        guard let interactivePopGestureRecognizer = navigationController.interactivePopGestureRecognizer else { return }
        panGestureRecognizer.require(toFail: interactivePopGestureRecognizer)
        panGestureRecognizer.delegate = self
//        panGestureRecognizer.addTarget(self, action: #selector(handlePan))
//        
//        navigationController.view.addGestureRecognizer(panGestureRecognizer)
        
        self.navigationController = navigationController
    }
    
    func beganTransition(initiallyInteractive: Bool) {
        heroInteractiveTransition.wantsInteractiveStart = initiallyInteractive
    }
    
    func isAnimating() -> Bool {
        heroInteractiveTransition.isAnimating()
    }
}
