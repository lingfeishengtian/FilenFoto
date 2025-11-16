//
//  SwiftUIProviderProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import SwiftUI

class ValueBridge<T>: ObservableObject {
    @Published var value: T
    
    init(_ value: T) {
        self.value = value
    }
}


enum SwiftUIViewFactoryViewType {
    case topBar, bottomBar, detailedView, noImagesAvailableView
}

protocol SwiftUIViewFactoryProtocol {
    func topBar(assetValueBridge: ValueBridge<WorkingSetFotoAsset>) -> any View
    func bottomBar(assetValueBridge: ValueBridge<WorkingSetFotoAsset>) -> any View
    func detailedView(assetValueBridge: ValueBridge<WorkingSetFotoAsset>) -> any View
    
    @ViewBuilder var noImagesAvailableView: any View { get }
}
