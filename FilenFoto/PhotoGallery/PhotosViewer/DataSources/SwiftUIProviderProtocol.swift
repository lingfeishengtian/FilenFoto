//
//  SwiftUIProviderProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import SwiftUI

protocol SwiftUIProviderProtocol {
    func topBar(with image: UIImage) -> any View
    func bottomBar(with image: UIImage) -> any View
    func detailedView(for image: UIImage) -> any View
}
