import PhotosUI
import AVKit
import SwiftUI
import UIKit

func assignGestures(
    to view: UIView, in context: (UIViewRepresentableContext<some ZoomablePannableViewContent>)
) {
    let pinchGestureRecognizer = UIPinchGestureRecognizer(
        target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
    let panGestureRecognizer = UIPanGestureRecognizer(
        target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))

    panGestureRecognizer.delegate = context.coordinator

    view.addGestureRecognizer(pinchGestureRecognizer)
    view.addGestureRecognizer(panGestureRecognizer)
}

struct ZoomablePhoto: ZoomablePannableViewContent {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var onSwipeUp: () -> Void
    var onSwipeDown: () -> Void
    @Binding var image: UIImage
    @State var associatedView: UIView = UIView()

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        imageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor),
        ])

        assignGestures(to: view, in: context)
        imageView.isUserInteractionEnabled = true

        view.sizeToFit()

        DispatchQueue.main.async {
            self.associatedView = imageView
        }
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView.subviews.first as? UIImageView else { return }
//        guard let view = uiView as? UIImageView else { return }
        if image != view.image {
            view.image = image
        }
    }

    func makeCoordinator() -> ZoomablePannableViewContentCoordinator {
        ZoomablePannableViewContentCoordinator(self)
    }
}

struct ZoomableLivePhoto: ZoomablePannableViewContent {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var onSwipeUp: () -> Void
    var onSwipeDown: () -> Void
    // TODO: Can this not be binding?
    @Binding var livePhoto: PHLivePhoto
    
    @State var associatedView: UIView = UIView()

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let livePhotoView = PHLivePhotoView()
        livePhotoView.livePhoto = livePhoto
        livePhotoView.contentMode = .scaleAspectFit
        livePhotoView.clipsToBounds = true
        
        livePhotoView.setContentHuggingPriority(.defaultLow, for: .vertical)
        livePhotoView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        livePhotoView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        livePhotoView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        livePhotoView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(livePhotoView)

        NSLayoutConstraint.activate([
            livePhotoView.topAnchor.constraint(equalTo: view.topAnchor),
            livePhotoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            livePhotoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            livePhotoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            livePhotoView.heightAnchor.constraint(equalTo: view.heightAnchor),
        ])

        assignGestures(to: view, in: context)

        view.sizeToFit()

        DispatchQueue.main.async {
            self.associatedView = livePhotoView
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // guard let view = uiView as? PHLivePhotoView else { return }
        // if livePhoto != view.livePhoto {
        //     view.livePhoto = livePhoto
        // }

        guard let view = uiView.subviews.first as? PHLivePhotoView else { return }
        if livePhoto != view.livePhoto {
            view.livePhoto = livePhoto
        }
    }

    func makeCoordinator() -> ZoomablePannableViewContentCoordinator {
        ZoomablePannableViewContentCoordinator(self)
    }
}
