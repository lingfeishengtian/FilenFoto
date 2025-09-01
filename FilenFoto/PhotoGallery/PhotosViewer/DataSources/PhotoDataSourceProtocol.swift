//
//  PhotoDataSourceProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import Foundation
import UIKit

protocol PhotoDataSourceProtocol {
    func numberOfPhotos() -> Int
    func photoAt(index: Int) -> UIImage? // TODO: Change to custom Photo Model
}
