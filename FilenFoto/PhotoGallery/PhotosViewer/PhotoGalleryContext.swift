//
//  PhotoContext.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/1/25.
//

import Foundation
import SwiftUI
import CoreData

class PhotoGalleryContext: ObservableObject {
    @Published var selectedPhotoId: PhotoIdentifier?
    
    // TODO: This might not be doable anymore
    let photoDataSource: any PhotoDataSourceProtocol
    let swiftUIProvider: any SwiftUIProviderProtocol
    
    init(photoDataSource: any PhotoDataSourceProtocol, swiftUIProvider: any SwiftUIProviderProtocol) {
        self.photoDataSource = photoDataSource
        self.swiftUIProvider = swiftUIProvider
    }
}
