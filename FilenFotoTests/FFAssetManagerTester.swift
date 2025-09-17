//
//  FFAssetManagerTester.swift
//  FilenFotoTests
//
//  Created by Hunter Han on 9/16/25.
//

import Foundation
import Photos
import Testing

@testable import FilenFoto

struct FFAssetManagerTester {
    var testAsset: PHAsset {
        // TODO: Request permissions first
        PHAsset.fetchAssets(with: nil).object(at: 0)
    }

    var testLivePhotoAsset: PHAsset {
        var finAsset: PHAsset?

        PHAsset.fetchAssets(with: nil).enumerateObjects { (asset, _, _) in
            if asset.mediaSubtypes.contains(.photoLive) {
                finAsset = asset
            }
        }

        if finAsset == nil {
            fatalError("Please add a live photo to the library to test")
        }

        return finAsset!
    }
    
    func ensureEnvironmentIsSetUpForTesting() {
        #expect(PhotoContext.shared.filenClient != nil)
        #expect(PhotoContext.shared.rootPhotoDirectory != nil)
    }

    @Test func testBasicAsset() async throws {
        ensureEnvironmentIsSetUpForTesting()
        let insertedAsset = try! await fetchAssetsFromLibrary(testAsset: testAsset)
        await uploadAssetsAndValidate(testAsset: testAsset, insertedFotoAsset: insertedAsset)
    }
    
    @Test func testLivePhotoAsset() async throws {
        ensureEnvironmentIsSetUpForTesting()
        let insertedAsset = try! await fetchAssetsFromLibrary(testAsset: testLivePhotoAsset)
        await uploadAssetsAndValidate(testAsset: testLivePhotoAsset, insertedFotoAsset: insertedAsset)
    }

    func fetchAssetsFromLibrary(testAsset: PHAsset) async throws -> FotoAsset {
        let assetsManager = FFAssetManager()

        let insertedFotoAsset = FFCoreDataManager.shared.insert(for: testAsset)
        let workingDirectory = workingDirectory(for: insertedFotoAsset)

        // Create working directory if it doesn't exist
        try? FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true, attributes: nil)

        do {
            try await assetsManager.fetchAssets(for: insertedFotoAsset, from: testAsset, writeTo: workingDirectory)
        } catch {
            #expect(Bool(false), "\(error)")
        }

        let resources = PHAssetResource.assetResources(for: testAsset)
        let numberOfResourcesInFinalDirectory = try FileManager.default.contentsOfDirectory(atPath: workingDirectory.path).count
        #expect(numberOfResourcesInFinalDirectory == resources.count)

        let remoteResources = insertedFotoAsset.remoteResources?.allObjects as? [RemoteResource] ?? []
        #expect(remoteResources.count == resources.count)
        for remoteResource in remoteResources {
            let fileThatShouldExist = workingDirectory.appending(path: remoteResource.uuid!.uuidString)
            #expect(FileManager.default.fileExists(atPath: fileThatShouldExist.path))

            // TODO: Validate hash
        }
        
        return insertedFotoAsset
    }
    
    func uploadAssetsAndValidate(testAsset: PHAsset, insertedFotoAsset: FotoAsset) async {
        let assetManager = FFAssetManager()
        let workingDirectory = workingDirectory(for: insertedFotoAsset)
        
        do {
            try await assetManager.uploadAssets(in: workingDirectory, for: insertedFotoAsset)
        } catch {
            #expect(Bool(false), "\(error)")
        }
        
        // TODO: At this point, the original assets have been moved into cache, so we should validate the state of the cache
        
        let remoteResources = insertedFotoAsset.remoteResources?.allObjects as? [RemoteResource] ?? []
        for remoteResource in remoteResources {
            let downloadLocation = temporaryDownloadLocation(for: remoteResource)
            
            do {
                try await PhotoContext.shared.filenClient!.downloadFileToPath(fileUuid: remoteResource.filenUuid!.uuidString, path: downloadLocation.path())
                let hashOfWorkingDirectoryFile = remoteResource.fileHashBinary!
                let hashOfDownloadedFile = Data(try FileManager.getSHA256(forFile: downloadLocation))
                
                #expect(hashOfDownloadedFile == hashOfWorkingDirectoryFile)
            } catch {
                #expect(Bool(false), "\(error)")
            }
        }
        
        // TODO: Delete files that were uploaded
    }
    
    func workingDirectory(for fotoAsset: FotoAsset) -> URL {
        TestResourceManager.shared.tempDir.appending(path: "FFAssetManagerTest").appending(component: fotoAsset.uuid!.uuidString)
    }
    
    func temporaryDownloadLocation(for remoteResource: RemoteResource) -> URL {
        TestResourceManager.shared.tempDir.appending(path: remoteResource.uuid!.uuidString)
    }
}
