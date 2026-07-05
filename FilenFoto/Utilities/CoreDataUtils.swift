//
//  CoreDataTypeUtils.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/10/25.
//

import Foundation
import CoreData

/// This file contains a lot of helper utilities and convienence wrappers for development
/// During development, a trouble I had was accidentally and unknowningly mutating the NSManagedObject causing race condition bugs. Furthermore, I
/// would also accidentally share objects that were in the wrong thread, causing nasty bugs. These helper utilities do checks during development to enforce
/// that functions that should only read NSManagedObjects should not be able to edit them at compile time. However, in order to not produce production
/// overhead, the types are designed (with macros) to be compiled out.
///
/// Furthermore, I include functions for creating temporary contexts, mutating those objects, and saving them again, hoping to boost the thread-safety of
/// my implementation. Although this helps, it does not eliminate bugs.

struct FFObjectID<T: NSManagedObject>: Hashable {
    let raw: NSManagedObjectID
    
    func getReadOnlyObject() -> ReadOnlyNSManagedObject<T>? {
        FFCoreDataManager.shared.readOnly(from: self)
    }
}

#if DEBUG
@dynamicMemberLookup
public struct ReadOnlyNSManagedObject<RawNSManagedObject: NSManagedObject> {
    private let object: RawNSManagedObject
    
    public init(_ object: RawNSManagedObject) {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

        if !isPreview {
            assert(!object.objectID.isTemporaryID)
            assert(FFCoreDataManager.shared.validateIsInBackgroundContext(object: object) || FFCoreDataManager.shared.validateIsInMainContext(object: object))
        }
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

func makeReadOnly<T: NSManagedObject>(_ object: T) -> ReadOnlyNSManagedObject<T> {
    ReadOnlyNSManagedObject(object)
}
#else
public typealias ReadOnlyNSManagedObject<RawNSManagedObject: NSManagedObject> = RawNSManagedObject

func makeReadOnly<T: NSManagedObject>(_ object: T) -> ReadOnlyNSManagedObject<T> {
    object
}

extension NSManagedObject {
    var underlyingObject: Self {
        self
    }
}
#endif

func typedID<T: NSManagedObject>(_ object: T) -> FFObjectID<T> {
    FFObjectID(raw: object.objectID)
}

#if DEBUG
func typedID<T: NSManagedObject>(_ object: ReadOnlyNSManagedObject<T>) -> FFObjectID<T> {
    typedID(object.underlyingObject)
}
#endif

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
