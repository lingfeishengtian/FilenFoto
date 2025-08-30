//
//  PhotoContextNavigationController.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import UIKit

class PhotoContextNavigationController: UINavigationController {
    var selectedPhotoIndex: Int?
    
    var photoDataSource: any PhotoDataSourceProtocol
    var swiftUIProvider: any SwiftUIProviderProtocol
    
    required init(photoDataSource: any PhotoDataSourceProtocol, swiftUIProvider: any SwiftUIProviderProtocol, rootViewController: UIViewController) {
        self.photoDataSource = photoDataSource
        self.swiftUIProvider = swiftUIProvider
        
        super.init(rootViewController: rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
