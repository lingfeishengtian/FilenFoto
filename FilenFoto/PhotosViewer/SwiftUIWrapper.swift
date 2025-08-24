//
//  SwiftUIWrapper.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import SwiftUI

struct PhotosViewer : UIViewControllerRepresentable {
    let photos: [UIImage]
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let rootPhotosViewer = PhotosViewerViewController()
        rootPhotosViewer.photos = photos
        
        let navigationController = UINavigationController(rootViewController: rootPhotosViewer)
        navigationController.navigationBar.isHidden = true

        return navigationController
    }
     
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
