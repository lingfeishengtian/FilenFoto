//
//  FotoAsset+Utilities.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/19/25.
//

import Foundation

extension FotoAsset {
    var remoteResourcesArray: [RemoteResource] {
        remoteResources?.allObjects as? [RemoteResource] ?? []
    }
}
