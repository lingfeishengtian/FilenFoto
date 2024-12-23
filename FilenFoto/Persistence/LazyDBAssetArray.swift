//
//  LazyDBAssetArray.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/17/24.
//

import Foundation

extension DBPhotoAsset {
    init(id: Int) {
        self.init(id: Int64(id), localIdentifier: UUID().uuidString, mediaType: .image, mediaSubtype: [], creationDate: .now, modificationDate: .now, location: nil, favorited: false, hidden: false, thumbnailFileName: "", burstIdentifier: nil, burstSelectionTypes: .userPick)
    }
}

fileprivate var latestAccessedID = -1

public class LazyDBPhotoAsset: Identifiable, Equatable {
    public let id: Int
    lazy var dbPhotoAsset: DBPhotoAsset = {
        MainActor.assumeIsolated {
            latestAccessedID = id
            return PhotoDatabase.shared.getDBPhotoStreamOptimized(index: id)!
        }
    }()
    
    static var lastAccessed: Int {
        latestAccessedID
    }
    
    public init(id: Int) {
        self.id = id
    }
    
    public static func == (lhs: LazyDBPhotoAsset, rhs: LazyDBPhotoAsset) -> Bool {
        lhs.id == rhs.id
    }
}

public struct LazyDBAssetArray: RandomAccessCollection, Identifiable {
    public var id: String {
        "LazyDBAssetArray\(startIndex)-\(endIndex)"
    }
    
    public subscript(position: Int) -> LazyDBPhotoAsset {
        return LazyDBPhotoAsset(id: position)
    }
    
    public subscript(bounds: Range<Int>) -> LazyDBAssetArray {
        LazyDBAssetArray(startIndex: bounds.lowerBound, endIndex: bounds.upperBound)
    }
    
    public func index(after i: Int) -> Int {
        i + 1
    }
    
    public func index(before i: Int) -> Int {
        i - 1
    }
    
    public func index(_ i: Int, offsetBy distance: Int) -> Int {
        i + distance
    }
    
    public func distance(from start: Int, to end: Int) -> Int {
        end - start
    }
    
    public var startIndex: Int = 0
    public var endIndex: Int = 0
    
    public typealias Element = LazyDBPhotoAsset
    public typealias Index = Int
    public typealias Indices = Range<Int>
    public typealias SubSequence = LazyDBAssetArray
}
