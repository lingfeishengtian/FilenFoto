//
//  CoreDataEnumAttributePropertyWrapper.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/15/25.
//

import CoreData
import Foundation

@propertyWrapper
struct AnyCoreDataEnumAttribute<
    Root,
    T: RawRepresentable,
    Storage
>
where
    Storage: FixedWidthInteger,
    T.RawValue: FixedWidthInteger
{
    let keyPath: ReferenceWritableKeyPath<Root, Storage>

    static subscript(
        _enclosingInstance instance: Root,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Root, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<Root, Self>
    ) -> T {
        get {
            let keyPath = instance[keyPath: storageKeyPath].keyPath
            let rawValue = instance[keyPath: keyPath]

            return T(rawValue: T.RawValue(truncatingIfNeeded: rawValue))!
        }

        set {
            let keyPath = instance[keyPath: storageKeyPath].keyPath

            instance[keyPath: keyPath] =
                Storage(truncatingIfNeeded: newValue.rawValue)
        }
    }

    @available(
        *, unavailable,
        message: "This property wrapper can only be applied to classes"
    )
    var wrappedValue: T {
        get { fatalError("Access through enclosing self only") }
        set { fatalError("Access through enclosing self only") }
    }
}

protocol CoreDataEnumAttributeContainer {
    typealias CoreDataEnumAttribute<T: RawRepresentable, Storage: FixedWidthInteger> = AnyCoreDataEnumAttribute<Self, T, Storage>
    where T.RawValue: FixedWidthInteger
}

extension NSManagedObject: CoreDataEnumAttributeContainer {}
