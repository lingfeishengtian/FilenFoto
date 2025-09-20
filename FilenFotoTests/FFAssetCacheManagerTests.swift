//
//  FFAssetCacheManager.swift
//  FilenFotoTests
//
//  Created by Hunter Han on 9/13/25.
//

import Foundation
import Photos
import Testing

@testable import FilenFoto

func generateRandomResourceType() -> PHAssetResourceType {
    let validTypes: [PHAssetResourceType] = [
        .photo,
        .video,
        .audio,
    ]

    return validTypes.randomElement()!
}

@MainActor
@Suite(.serialized)
struct FFAssetCacheManagerTests {
    let context = FFCoreDataManager.shared.mainContext

    /// This resets every test
    func generateTestRemoteResources(count: Int = 10) -> [RemoteResource] {
        let parentAsset = FotoAsset(context: context)
        parentAsset.dateCreated = Date()
        parentAsset.dateModified = Date()
        parentAsset.uuid = UUID()
        
        let resources = (0..<count).map { i in
            let remoteResource = RemoteResource(context: context)
            remoteResource.assetResourceType = generateRandomResourceType()
            remoteResource.filenUuid = UUID()
            remoteResource.parentAsset = parentAsset

            return remoteResource
        }
        
        try! context.save()
        
        return resources
    }

    var maxNumberInCache: Int {
        Int(
            floor(Double(FFResourceCacheManager.shared.photoCacheMaximumSize) / Double(TestResourceManager.shared.testImageFileSize)))
    }

    @Test func testSimpleInsertion() async {
        let testRemoteResources = generateTestRemoteResources(count: 10)

        insert(remoteResources: testRemoteResources)
        await FFCoreDataManager.shared.saveContextIfNeeded()
        assertCoreDataIntegrity(withOriginal: testRemoteResources)
        clear(remoteResources: testRemoteResources)
    }

    @Test func testCachePushout() async {
        let testRemoteResources = generateTestRemoteResources(count: maxNumberInCache + 1)

        insert(remoteResources: testRemoteResources)
        await FFCoreDataManager.shared.saveContextIfNeeded()
        assertCoreDataIntegrity(withOriginal: testRemoteResources)
        clear(remoteResources: testRemoteResources)
    }

    func insert(remoteResources: [RemoteResource]) {
        for resource in remoteResources {
            #expect(throws: Never.self) {
                try FFResourceCacheManager.shared.insert(remoteResource: resource, fileUrl: TestResourceManager.shared.testImage)
            }
        }
    }

    func assertCoreDataIntegrity(withOriginal remoteResources: [RemoteResource]) {
        // Ensure all remote resources are present
        let fetchRequest = RemoteResource.fetchRequest()
        let coreDataResults = try? context.fetch(fetchRequest)

        #expect(coreDataResults?.count == remoteResources.count)

        for (_, coreDataRemoteResource) in coreDataResults?.enumerated() ?? [].enumerated() {
            let correspondingRemoteResource = remoteResources.first { $0.filenUuid == coreDataRemoteResource.filenUuid }

            #expect(correspondingRemoteResource != nil)
        }

        // Ensure cache integrity
        let fetchCacheRequest = CachedResource.fetchRequest()
        let cacheResults = try? context.fetch(fetchCacheRequest)

        #expect(cacheResults?.count == min(remoteResources.count, maxNumberInCache))

        for (_, cachedResource) in cacheResults?.enumerated() ?? [].enumerated() {
            let correspondingRemoteResource = remoteResources.first { $0.filenUuid == cachedResource.remoteResource?.filenUuid }

            #expect(correspondingRemoteResource != nil)
        }
        
        // Ensure number of files on disk is correct
        checkCacheFolder(has: min(remoteResources.count, maxNumberInCache))
    }
    
    func clear(remoteResources: [RemoteResource]) {
        for resource in remoteResources {
            context.delete(resource)
        }
        
        try? context.save()
        
        checkCacheFolder(has: 0)
    }
    
    func checkCacheFolder(has expectedCount: Int) {
        let cacheFolder = FFResourceCacheManager.shared.persistedPhotoCacheFolder
        let fileManager = FileManager.default
        let filesOnDisk = (try? fileManager.contentsOfDirectory(at: cacheFolder, includingPropertiesForKeys: nil)) ?? []
        #expect(filesOnDisk.count == expectedCount)
    }
}
