//
//  WorkingSet.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/4/25.
//

import Foundation
import CoreData
import os

final class FFWorkingSet {
    private init() {}
    static let `default` = FFWorkingSet()
    
    private let workingSetMap = NSMapTable<NSManagedObjectID, WorkingSetFotoAsset>(
        keyOptions: .strongMemory,
        valueOptions: .weakMemory
    )
    
    private let lock = OSAllocatedUnfairLock()
    
    func requestWorkingSet(for asset: FotoAsset) -> WorkingSetFotoAsset {
        let assetObjectId = asset.objectID
        let typedObjectId = typedID(asset)
        
        return lock.withLock {
            if let workingAsset = workingSetMap.object(forKey: assetObjectId) {
                return workingAsset
            }
            
            let workingAsset = WorkingSetFotoAsset(asset: typedObjectId)

            workingSetMap.setObject(workingAsset, forKey: assetObjectId)
            return workingAsset
        }
    }
    
    #if DEBUG
    func assertWorkingSetIsEmpty() {
        lock.withLock {
            assert(workingSetMap.count == 0)
        }
    }
    #endif
}
