import SwiftUI
import AVFoundation
import AVKit

struct ZoomableVideo: UIViewControllerRepresentable {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var onSwipeUp: () -> Void
    var onSwipeDown: () -> Void
    var video: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = video
        playerViewController.showsPlaybackControls = true

        // Add gesture recognizers to the playerViewController's view
        assignGestures(to: playerViewController.view, in: context)

        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = video
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func assignGestures(to view: UIView, in context: Context) {
        // Add pinch gesture recognizer
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        pinchGestureRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(pinchGestureRecognizer)

        // Add pan gesture recognizer
        let panGestureRecognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        panGestureRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(panGestureRecognizer)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: ZoomableVideo

        init(_ parent: ZoomableVideo) {
            self.parent = parent
        }

        // Allow gestures to be recognized simultaneously
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began, .changed:
                parent.scale = gesture.scale
            case .ended:
                withAnimation {
                    self.parent.scale = 1.0
                }
                gesture.scale = 1.0
            default:
                break
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began, .changed:
                let translation = gesture.translation(in: gesture.view)
                parent.offset = CGSize(width: translation.x, height: translation.y)
            case .ended:
                let velocity = gesture.velocity(in: gesture.view)
                if velocity.y > 0 {
                    parent.onSwipeDown()
                } else {
                    parent.onSwipeUp()
                }
                withAnimation {
                    self.parent.offset = .zero
                }
                gesture.setTranslation(.zero, in: gesture.view)
            default:
                break
            }
        }
    }
}