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
//    func initiateProtocol(for photo: PHAsset, with fotoAsset: FotoAsset) async -> Bool
    func initiateProtocol(with fotoAsset: FotoAsset) async -> Bool
}
