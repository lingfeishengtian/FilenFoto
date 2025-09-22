//
//  PhotoActionProviderProtocol.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/3/25.
//

import Foundation
import Photos
import CoreData

typealias ProviderCompletion = () -> Void

protocol PhotoActionProviderDelegate: Actor {
    nonisolated var version: Int16 { get }
    
    /// If this provider was never run before, initialize its protocol
    func initiateProtocol(for workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset) async throws -> ProviderCompletion?
    
    /// This will be called incremently. For example, if the currentVersion is 1, you are responsible for upgrading it to version 2. You are expected to implement CoreData actions responsibly and guarantee data integrity
    func incrementlyMigrate(_ workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset, from currentVersion: Int16) async throws -> ProviderCompletion?
    
    /// This provider failed to run actions previously try to rerun the action
    func retryFailedActions(for workingSetAsset: WorkingSetFotoAsset, with fotoAsset: FotoAsset) async throws -> ProviderCompletion?
}
