//
//  Types.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/7/25.
//

import Foundation

struct ThumbnailIndex {
    let bucket1: UInt8
    let bucket2: UInt8

    init(_ uuid: UUID) {
        let bytes = uuid.uuid

        bucket1 = bytes.14
        bucket2 = bytes.15
    }
    
    func directory(rootDirectory: URL) -> URL {
        let bucket1String = String(format: "%02x", bucket1)
        let bucket2String = String(format: "%02x", bucket2)
        
        return rootDirectory.appendingPathComponent(bucket1String).appendingPathComponent(bucket2String)
    }
}
