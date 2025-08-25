//
//  SwiftUIWrapper.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import SwiftUI

struct PhotosViewer<Content: View>: UIViewControllerRepresentable {
    /// Data source for photos to be displayed, the view does not care how you get the photos, but your operations should **NOT** be anything greater than O(log n) complexity for the best user experience
    /// Furthermore, utilize caching where possible to speed up photo retrieval since the view may request the same photo multiple times
    let photoDataSource: PhotoDataSourceProtocol
    /// This will take up half the screen where the top half is the photo viewer and the bottom half is the detailed photo view
    /// Hosted in a UIHostingController
    let detailedPhotoView: ((UIImage) -> Content) // TODO: Create custom datatype for detailed photo view
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let rootPhotosViewer = PhotosViewerViewController()
        rootPhotosViewer.photoDataSource = photoDataSource
        rootPhotosViewer.detailedPhotoViewBuilder = { image in
            AnyView(detailedPhotoView(image))
        }
        
        let navigationController = UINavigationController(rootViewController: rootPhotosViewer)
        navigationController.navigationBar.isHidden = true

        return navigationController
    }
     
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
