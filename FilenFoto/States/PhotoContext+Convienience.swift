//
//  PhotoContext+Convienience.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/17/25.
//

import Foundation


extension PhotoContext {
    func unwrappedFilenClient() throws -> FilenClient  {
        guard let filenClient else {
            throw FilenFotoError.filenClientUnavailable
        }
        
        return filenClient
    }
    
    func unwrappedRootFolderDirectory() throws -> UUID  {
        guard let rootPhotoDirectory else {
            throw FilenFotoError.filenRootFolderDirectoryUnavailable
        }
        
        return rootPhotoDirectory
    }
}
