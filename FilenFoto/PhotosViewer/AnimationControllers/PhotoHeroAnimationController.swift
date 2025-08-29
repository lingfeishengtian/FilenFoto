//
//  PhotoHeroAnimationController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

class PhotoHeroAnimationController: NSObject {
    let heroInteractiveTransition = InteractiveHeroAnimatedTransition()
    let detailedInfoTransition = DetailedInfoTransition()
    let detailedInfoInteractiveTransition = DetailedInfoInteractiveTransition()
    
    private weak var navigationController: UINavigationController?
    private let panGestureRecognizer = UIPanGestureRecognizer()
    
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
    
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let navigationController = navigationController, let topViewController = navigationController.topViewController else { return }
        
        if let pagedVC = topViewController as? PagedPhotoDetailViewController, let view = pagedVC.view {
            let returnedView = view.hitTest(gestureRecognizer.location(in: view), with: nil)
            
                if gestureRecognizer.state == .began {
                    navigationController.popViewController(animated: true)
                }
            
            if returnedView == (pagedVC.pagedController.viewControllers?.first as! PhotoPageViewController).imageView {
            }
        }
    }
}
