//
//  SwiftUIWrapper.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import SwiftUI

struct PhotosViewer : UIViewControllerRepresentable {
    let photoDataSource: PhotoDataSourceProtocol
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let rootPhotosViewer = PhotosViewerViewController()
        rootPhotosViewer.photoDataSource = photoDataSource
        
        let navigationController = UINavigationController(rootViewController: rootPhotosViewer)
        navigationController.navigationBar.isHidden = true

        return navigationController
    }
     
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
