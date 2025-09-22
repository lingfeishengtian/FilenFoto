//
//  ProviderStatus+CoreDataClass.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/21/25.
//
//

public import Foundation
public import CoreData

public typealias ProviderStatusCoreDataClassSet = NSSet

@objc(ProviderStatus)
public class ProviderStatus: NSManagedObject {
    @CoreDataEnumAttribute(keyPath: \.providerIDRaw) var provider: AvailableProvider
    @CoreDataEnumAttribute(keyPath: \.stateRaw) var state: ProviderState
}
