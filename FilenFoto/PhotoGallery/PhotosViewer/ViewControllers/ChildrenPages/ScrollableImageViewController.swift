//
//  FFDetailedPhotoViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/24/25.
//

import Foundation
import UIKit

class ScrollableImageViewController: ChildPageTemplateViewController, PagedPhotoHeroAnimatorDelegate {
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    var contentView: UIView!
    
    lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//    lazy var panGestureRecognizer = UIPanGestureRecognizer()
    lazy var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        recognizer.numberOfTapsRequired = 2
        return recognizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: self.parent!.view.frame) // TODO: FInd better way to do this
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        contentView = UIImageView(frame: self.parent!.view.frame)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        imageView = UIImageView(frame: self.parent!.view.frame)
        imageView.contentMode = .scaleAspectFill

        contentView.addSubview(imageView)
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        
        self.view.addGestureRecognizer(panGestureRecognizer)
        self.view.addGestureRecognizer(doubleTapGestureRecognizer)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        panGestureRecognizer.delegate = self
        
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

        guard let image else {
            return
        }

        self.imageView.frame = centeredAndResizedFrame(for: image, in: self.contentView.frame)
    }
    
    // MARK: - Gesture Recognizers
    var initialPanDirection: Direction = .none

    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)

        switch gestureRecognizer.state {
        case .began:
            if animationController.isAnimating() {
                return
            }
            
            commitLocalSelectedPhotoIndex()

            if direction(of: velocity) == .down {
                animationController.beginDismissingInteractiveTransition()
                dismiss(animated: true)

                animationController.heroInteractiveTransition.handlePan(gestureRecognizer)
            } else {
                let pagedVC = DetailPageViewController(animationController: animationController, photoGalleryContext: photoGalleryContext)
                pagedVC.animationController = animationController

                animationController.beginDetailedInfoInteractiveTransition(initiallyInteractive: true, from: pagingViewController, to: pagedVC)
                
                navigationController?.pushViewController(pagedVC, animated: true)
                animationController.detailedInfoInteractiveTransition.handlePan(gestureRecognizer)
            }

            initialPanDirection = direction(of: velocity)
        default:
            if initialPanDirection == .down {
                animationController.heroInteractiveTransition.handlePan(gestureRecognizer)
            }

            if initialPanDirection == .up {
                animationController.detailedInfoInteractiveTransition.handlePan(gestureRecognizer)
            }
        }
    }

    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: gestureRecognizer.location(in: contentView), view: contentView)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    func getAnimationReferences(in view: UIView) -> AnimationReferences {
        view.layoutIfNeeded()
        configure(with: image)
        
        return AnimationReferences(
            imageReference: imageView,
            frame: scrollView.convert(
                imageView.frame,
                to: view
            )
        )
    }
}
