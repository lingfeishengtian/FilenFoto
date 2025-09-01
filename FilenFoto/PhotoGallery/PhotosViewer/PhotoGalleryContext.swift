//
//  PhotoContext.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/1/25.
//

import Foundation
import SwiftUI

class PhotoGalleryContext: ObservableObject {
    @Published var selectedPhotoIndex: Int?
    
    var photoDataSource: any PhotoDataSourceProtocol
    var swiftUIProvider: any SwiftUIProviderProtocol
    
    init(photoDataSource: any PhotoDataSourceProtocol, swiftUIProvider: any SwiftUIProviderProtocol) {
        self.photoDataSource = photoDataSource
        self.swiftUIProvider = swiftUIProvider
    }
}
