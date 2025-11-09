//
//  SwiftUIProviderProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import SwiftUI

protocol SwiftUIProviderProtocol {
    func topBar(with image: WorkingSetFotoAsset) -> any View
    func bottomBar(with image: WorkingSetFotoAsset) -> any View
    func detailedView(for image: WorkingSetFotoAsset) -> any View
    func noImagesAvailableView() -> any View
}
