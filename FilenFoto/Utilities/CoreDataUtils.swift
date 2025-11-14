//
//  CoreDataTypeUtils.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/10/25.
//

import Foundation
import CoreData

struct FFObjectID<T: NSManagedObject>: Hashable {
    let raw: NSManagedObjectID
    
    func getReadOnlyObject() -> ReadOnlyNSManagedObject<T>? {
        FFCoreDataManager.shared.readOnly(from: self)
    }
}

@dynamicMemberLookup
public struct ReadOnlyNSManagedObject<RawNSManagedObject: NSManagedObject> {
    private let object: RawNSManagedObject
    
    public init(_ object: RawNSManagedObject) {
        assert(!object.objectID.isTemporaryID)
        assert(FFCoreDataManager.shared.validateIsInBackgroundContext(object: object) || FFCoreDataManager.shared.validateIsInMainContext(object: object))
        self.object = object
    }
    
    public var underlyingObject: RawNSManagedObject {
        get {
            object
        }
    }
    
    /// Exposes only read-only KeyPaths (compile-time safety)
    public subscript<T>(dynamicMember keyPath: KeyPath<RawNSManagedObject, T>) -> T {
        object[keyPath: keyPath]
    }
}

func typedID<T: NSManagedObject>(_ object: T) -> FFObjectID<T> {
    FFObjectID(raw: object.objectID)
}

func typedID<T: NSManagedObject>(_ object: ReadOnlyNSManagedObject<T>) -> FFObjectID<T> {
    typedID(object.underlyingObject)
}

func withTemporaryManagedObjectContext<T: NSManagedObject, R>(
    _ objectID: FFObjectID<T>,
    _ body: (T, NSManagedObjectContext) async throws -> R
) async throws -> R {
    let temporaryBackgroundContext = FFCoreDataManager.shared.newChildContext()
    let object = temporaryBackgroundContext.object(with: objectID.raw) as? T
    
    guard let object else {
        throw FilenFotoError.coreDataContext
    }
    
    let returnValue = try await body(object, temporaryBackgroundContext)
    
    try temporaryBackgroundContext.save()
    await FFCoreDataManager.shared.saveContextIfNeeded()
    
    return returnValue
}

func withTemporaryManagedObjectContext<T: NSManagedObject, R>(
    _ objectID: FFObjectID<T>,
    _ body: (T) async throws -> R
) async throws -> R {
    return try await withTemporaryManagedObjectContext(objectID) { object, _ in
        return try await body(object)
    }
}
