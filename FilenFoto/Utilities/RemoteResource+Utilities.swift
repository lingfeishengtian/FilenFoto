//
//  RemoteResource.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/14/25.
//

import Foundation

extension RemoteResource {
    func fileURL(in directory: URL) -> URL? {
        guard let fileName = uuid?.uuidString else {
            return nil
        }
        
        return directory.appending(path: fileName)
    }
    
    override public func validateForDelete() throws {
        try super.validateForDelete()
        
        if filenUuid != nil {
            throw FilenFotoError.remoteResourceStillExistsInFilen
        }
    }
}
