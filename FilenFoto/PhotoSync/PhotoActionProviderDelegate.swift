//
//  PhotoActionProviderProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/3/25.
//

import Foundation
import Photos

protocol PhotoActionProviderDelegate {
    func initiateProtocol(for photo: PHAsset, with identifier: UUID) -> Progress
}
