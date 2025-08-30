//
//  PhotoDetailViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import AVKit
import Foundation
import SwiftUI
import UIKit

func generateTestView() -> some View {
    Text("Test")
        .frame(maxWidth: .infinity)
}

class PhotoPageViewController: FFParentImageViewController {
    var scrollView: UIScrollView = UIScrollView() // TODO: This variables looks different from rest, find better solution
    var swiftUITopBar: UIHostingController<AnyView>!
    var swiftUIBottomBar: UIHostingController<AnyView>!

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

        swiftUITopBar = UIHostingController(rootView: AnyView(generateTestView()))
        swiftUIBottomBar = UIHostingController(rootView: AnyView(generateTestView()))

        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.view.addSubview(scrollView)
        self.addChild(swiftUITopBar)
        self.addChild(swiftUIBottomBar)
        self.view.addSubview(swiftUITopBar.view)
        self.view.addSubview(swiftUIBottomBar.view)

        self.view.addGestureRecognizer(panGestureRecognizer)
        self.view.addGestureRecognizer(doubleTapGestureRecognizer)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        swiftUITopBar.view.translatesAutoresizingMaskIntoConstraints = false
        swiftUIBottomBar.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            swiftUITopBar.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            swiftUITopBar.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            swiftUITopBar.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            swiftUITopBar.view.heightAnchor.constraint(equalToConstant: 100),

            swiftUIBottomBar.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            swiftUIBottomBar.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            swiftUIBottomBar.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            swiftUIBottomBar.view.heightAnchor.constraint(equalToConstant: 100),

            scrollView.topAnchor.constraint(equalTo: swiftUITopBar.view.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: swiftUIBottomBar.view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])

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

        self.imageView.frame = centeredAndResizedFrame(for: image, in: self.scrollView.frame)

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
            if animationController.isAnimating() {
                return
            }

            if direction(of: velocity) == .down {
                animationController.beganTransition(initiallyInteractive: true)
                navigationController?.popViewController(animated: true)

                animationController.heroInteractiveTransition.handlePan(gestureRecognizer)
            } else {
                let pagedVC = PagedPhotoDetailViewController()
                pagedVC.animationController = animationController
                pagedVC.PageType = DetailedPhotoViewController.self

                animationController.beganTransition(initiallyInteractive: true)
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
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: gestureRecognizer.location(in: imageView), view: imageView)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    override func getAnimationReferences(in view: UIView) -> AnimationReferences {
        self.view.layoutIfNeeded()
        
        return AnimationReferences(
            imageReference: imageView,
            frame: scrollView.convert(
                imageView.frame,
                to: view
            )
        )
    }
}
