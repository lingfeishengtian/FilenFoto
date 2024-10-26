import SwiftUI
import AVKit

struct ZoomableVideo: ZoomablePannableViewControllerContent {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var scrolling: Bool
    var onSwipeUp: () -> Void
    var onSwipeDown: () -> Void
    var video: AVPlayer
    @State var associatedView: UIView = UIView()
    @State private var isFullScreenObserver: NSKeyValueObservation?

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let view = UIScrollView()
        view.backgroundColor = .clear

        let playerViewController = AVPlayerViewController()
        playerViewController.player = video
        playerViewController.view.backgroundColor = .clear
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(playerViewController.view)
        
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        view.sizeToFit()

        DispatchQueue.main.async {
            self.associatedView = playerViewController.view
        }
        
        ZoomablePannableViewContentCoordinator.assignGestures(to: playerViewController.view, in: context.coordinator)
        
        playerViewController.view.isUserInteractionEnabled = true

        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = video
    }

    func makeCoordinator() -> ZoomablePannableViewContentCoordinator {
        ZoomablePannableViewContentCoordinator(self)
    }
}
