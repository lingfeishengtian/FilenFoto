//
//  PhotoActionProviderProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/3/25.
//

import Foundation
import Photos
import CoreData

protocol PhotoActionProviderDelegate {
    func initiateProtocol(with workingSetAsset: WorkingSetFotoAsset) async -> Bool
}
