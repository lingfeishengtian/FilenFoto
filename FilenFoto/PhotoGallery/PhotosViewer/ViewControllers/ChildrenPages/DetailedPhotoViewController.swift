//
//  DetailedPhotoViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import AVKit
import Foundation
import SwiftUI
import UIKit
import os


let IMAGE_PERCENT_OF_SCREEN: CGFloat = 0.5

class DetailedPhotoViewController: ChildPageTemplateViewController, PagedPhotoHeroAnimatorDelegate{
    private let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "DetailedPhotoViewController")
    
    var swiftUIView: UIHostingController<AnyView>!
    lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    
    func calculateImageFrame() -> CGRect {
        CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height * IMAGE_PERCENT_OF_SCREEN)
    }

    func calculateSwiftUIFrame() -> CGRect {
        CGRect(
            x: 0, y: view.frame.height * IMAGE_PERCENT_OF_SCREEN, width: view.frame.width, height: view.frame.height * (1 - IMAGE_PERCENT_OF_SCREEN))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        image.frame = calculateImageFrame()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true

        swiftUIView = UIHostingController(rootView: AnyView(swiftUIProvider.detailedView(for: image.workingAsset)))

        swiftUIView.view.frame = calculateSwiftUIFrame()
        swiftUIView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        panGestureRecognizer.delegate = self
        
        self.view.addSubview(image)
        self.view.addSubview(swiftUIView.view)
        self.view.addGestureRecognizer(panGestureRecognizer)
    }

    // MARK: - Gesture Recognizers
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            commitLocalSelectedPhotoIndex()
            animationController.beginDismissingInteractiveTransition()
            self.navigationController?.popViewController(animated: true)
            self.animationController.detailedInfoInteractiveTransition.handlePan(gestureRecognizer)
        default:
            self.animationController.detailedInfoInteractiveTransition.handlePan(gestureRecognizer)
        }
    }
    
    func getAnimationReferences(in view: UIView) -> AnimationReferences {
        return AnimationReferences(imageReference: self.image, frame: self.view.convert(calculateImageFrame(), to: view))
    }
}
