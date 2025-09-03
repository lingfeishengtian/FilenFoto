//
//  SwiftUIWrapper.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import SwiftUI

struct PhotosViewer: UIViewControllerRepresentable {
    /// Data source for photos to be displayed, the view does not care how you get the photos, but your operations should **NOT** be anything greater than O(log n) complexity for the best user experience
    /// Furthermore, utilize caching where possible to speed up photo retrieval since the view may request the same photo multiple times
    let photoDataSource: PhotoDataSourceProtocol
    // TODO: Write docs
    let swiftUIProvider: SwiftUIProviderProtocol

    func makeUIViewController(context: Context) -> PhotosViewerViewController {
        let rootPhotosViewer = PhotosViewerViewController(
            photoGalleryContext: PhotoGalleryContext(photoDataSource: photoDataSource, swiftUIProvider: swiftUIProvider))

        return rootPhotosViewer
    }

    func updateUIViewController(_ uiViewController: PhotosViewerViewController, context: Context) {
        // TODO: Write an update function maybe...
    }
}
