//
//  PhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import AVKit
import Foundation
import UIKit

class PhotoPageViewController: FFParentImageViewController {
    var scrollView: UIScrollView!

    lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        recognizer.numberOfTapsRequired = 2
        return recognizer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView = UIScrollView(frame: self.view.frame)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.zoomScale = 1.0
        scrollView.delegate = self

        imageView = UIImageView(frame: self.view.frame)
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        scrollView.addSubview(imageView)

        panGestureRecognizer.delegate = self

        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.view.addSubview(scrollView)
        self.view.addGestureRecognizer(panGestureRecognizer)
        self.view.addGestureRecognizer(doubleTapGestureRecognizer)

        configure(with: image)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configure(with: image)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configure(with: image)
    }

    func configure(with image: UIImage?) {
        self.imageView.image = image

        centerAndResize(imageView: self.imageView, in: self.scrollView.frame)
        
        let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width) / 2, 0.0)
        let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height) / 2, 0.0)
        self.scrollView.contentSize = CGSize(width: imageView.frame.width + offsetX, height: imageView.frame.height + offsetY)
    }
    
    // MARK: - Gesture Recognizers
    var initialPanDirection: Direction = .none

    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)

        switch gestureRecognizer.state {
        case .began:
            if direction(of: velocity) == .down {
                animationController.isInteractive = true
                navigationController?.popViewController(animated: true)
            } else {
                animationController.isInteractive = true
                let pagedVC = PagedPhotoDetailViewController()
                pagedVC.animationController = animationController
                pagedVC.PageType = DetailedPhotoViewController.self
                
                navigationController?.pushViewController(pagedVC, animated: true)
            }
            
            initialPanDirection = direction(of: velocity)
        case .changed:
            if animationController.isInteractive && initialPanDirection == .down {
                animationController.heroInteractiveTransition.handlePan(gestureRecognizer)
            }
            
            if initialPanDirection == .up {
                animationController.detailedInfoInteractiveTransition.handlePan(gestureRecognizer)
            }
        case .ended:
            if animationController.isInteractive && initialPanDirection == .down {
                animationController.heroInteractiveTransition.handlePan(gestureRecognizer)
                animationController.isInteractive = false
            }
            
            if initialPanDirection == .up {
                animationController.detailedInfoInteractiveTransition.handlePan(gestureRecognizer)
                animationController.isInteractive = false
            }
        default:
            // TODO: Remove this debug print
            print("Unhandled gesture state: \(gestureRecognizer.state)")
        }
    }

    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: gestureRecognizer.location(in: imageView), view: imageView)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    override func getAnimationReferences(in view: UIView) -> AnimationReferences {
        return AnimationReferences(imageReference: self.imageView, frame: self.scrollView.frame)
    }
}
