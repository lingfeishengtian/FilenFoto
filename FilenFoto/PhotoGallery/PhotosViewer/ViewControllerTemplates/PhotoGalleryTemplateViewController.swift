//
//  PhotoGalleryTemplateViewController.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/1/25.
//

import Foundation
import UIKit
import Combine

class PhotoGalleryTemplateViewController: UIViewController, PhotoContextDelegate {
    var photoGalleryContext: PhotoGalleryContext
    
    var cancellable: AnyCancellable?
    
    func willUpdateSelectedPhotoIndex(_ newIndex: Int?) { }
    
    init (photoGalleryContext: PhotoGalleryContext) {
        self.photoGalleryContext = photoGalleryContext
        
        super.init(nibName: nil, bundle: nil)
        
        self.cancellable = self.photoGalleryContext.$selectedPhotoIndex.sink { [weak self] newIndex in
            guard let self else { return }
            self.willUpdateSelectedPhotoIndex(newIndex)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
