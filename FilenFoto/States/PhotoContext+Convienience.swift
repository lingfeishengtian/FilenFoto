//
//  PhotoContext+Convienience.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/17/25.
//

import Foundation

private enum PhotoContextConvienienceError: Error {
    case filenClientUnavailable
    case rootFolderDirectoryUnavailable
}

extension PhotoContext {
    func unwrappedFilenClient() throws -> FilenClient  {
        guard let filenClient else {
            throw PhotoContextConvienienceError.filenClientUnavailable
        }
        
        return filenClient
    }
    
    func unwrappedRootFolderDirectory() throws -> UUID  {
        guard let rootPhotoDirectory else {
            throw PhotoContextConvienienceError.rootFolderDirectoryUnavailable
        }
        
        return rootPhotoDirectory
    }
}
